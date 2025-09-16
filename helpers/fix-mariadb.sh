#!/usr/bin/env bash
# =============================================================================
# fix-mariadb.sh Version 1.0
# MariaDB / InnoDB Recovery Script for NEMS Linux
# -----------------------------------------------------------------------------
# Purpose : Repair a corrupted MariaDB InnoDB database following the upstream
#           Raspberry Pi OS / Debian upgrade that breaks the database engine.
# Note    : This is not a user script. It is intended to be run by dev
#           following a clean database restore.
# Author  : Robbie Ferguson
# License : (c) 2025 Robbie Ferguson — Released under the Apache License 2.0
# =============================================================================

# Step 1: init as dev user
#         (which restores sample DB and grants access to nconf)
# Step 2: Run Patch #17
# Step 3: Run this script

set -euo pipefail

# =======================
# Config – change if needed
# =======================
SERVICE="mariadb"
DATADIR="/var/lib/mysql"
LOGFILE_CANDIDATES=("/var/log/mysql/error.log" "/var/log/mariadb/mariadb.log")

BACKUP_ROOT="/root/mysql-recovery"
TS="$(date +%F-%H%M%S)"
BK_DATADIR="${BACKUP_ROOT}/datadir-backup-${TS}"
BK_LOGDIR="${BACKUP_ROOT}/logs-${TS}"
DUMPDIR="${BACKUP_ROOT}/dumps-${TS}"
RECOVERY_CNF="/etc/mysql/mariadb.conf.d/zz-innodb-recovery.cnf"

MYSQL_SOCK_DEFAULT="/var/run/mysqld/mysqld.sock"
MYSQL_USER="root"
MYSQL_ROOT_PWD='nagiosadmin'
export MYSQL_PWD="$MYSQL_ROOT_PWD"   # used by mysql/mysqldump; hides from ps
MYSQL="mysql -u$MYSQL_USER -p$MYSQL_PWD"
MYSQLDUMP="mysqldump -u$MYSQL_USER -p$MYSQL_PWD"
MARIADB_INSTALL_DB="mariadb-install-db"

# =======================
# Helpers
# =======================
need_root() { [[ $EUID -eq 0 ]] || { echo "Run as root." >&2; exit 1; }; }
stop_db()   { systemctl stop "$SERVICE" || true; }
start_db()  { systemctl start "$SERVICE" || true; }
wait_ready() {
  local tries=60
  while (( tries-- )); do
    if [[ -S "$MYSQL_SOCK_DEFAULT" ]] && mysql --protocol=SOCKET -uroot -p"${MYSQL_PWD}" -e "SELECT 1;" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.3
  done
  return 1
}
write_recovery_cnf() {
  local lvl="$1"
  cat > "$RECOVERY_CNF" <<EOF
# Auto-added for recovery on $TS
[mysqld]
innodb_force_recovery = $lvl
innodb_print_all_deadlocks = ON
EOF
}
rm_recovery_cnf() { [[ -f "$RECOVERY_CNF" ]] && rm -f "$RECOVERY_CNF"; }
log() { printf "\n=== %s ===\n" "$*"; }

# =======================
# 0) Backups
# =======================
need_root
mkdir -p "$BK_DATADIR" "$BK_LOGDIR" "$DUMPDIR"

log "Stopping MariaDB (if running)"
stop_db

log "Backing up current datadir to $BK_DATADIR"
rsync -aHAX --numeric-ids "$DATADIR/" "$BK_DATADIR/"

log "Backing up logs to $BK_LOGDIR"
for lf in "${LOGFILE_CANDIDATES[@]}"; do [[ -f "$lf" ]] && cp -a "$lf" "$BK_LOGDIR/"; done || true

# =======================
# 1) Start with innodb_force_recovery (1→4) to allow reads
# =======================
RECOVERY_LEVEL=0
for lvl in 1 2 3 4; do
  log "Attempting start with innodb_force_recovery=$lvl"
  write_recovery_cnf "$lvl"
  start_db
  if wait_ready; then RECOVERY_LEVEL="$lvl"; log "Server up at level $lvl"; break; fi
  log "Failed at level $lvl; stopping and trying next"
  stop_db; rm_recovery_cnf
done
if [[ "$RECOVERY_LEVEL" -eq 0 ]]; then
  echo "FATAL: Could not start MariaDB with innodb_force_recovery=1..4." >&2
  echo "Backups are under $BACKUP_ROOT." >&2
  exit 2
fi

# =======================
# 2) Dump non-system DBs
# =======================
log "Enumerating databases"
DBS=$($MYSQL -N -e "SHOW DATABASES" | egrep -v '^(information_schema|performance_schema|mysql|sys)$' || true)
if [[ -z "$DBS" ]]; then
  log "No user databases found to dump."
else
  log "Dumping databases to $DUMPDIR"
  for db in $DBS; do
    log "  -> $db"
    $MYSQLDUMP --databases "$db" \
      --single-transaction --routines --triggers --events \
      --hex-blob --skip-lock-tables > "$DUMPDIR/$db.sql"
  done
fi

# Dump users/roles/grants from the mysql schema (MariaDB 10.4+)
# Uses REPLACE so it overwrites defaults on import without duplicate-key errors.
PRIV_DUMP="${DUMPDIR}/_mysql_privileges.sql"
$MYSQLDUMP --skip-lock-tables --skip-triggers --no-create-info --replace \
  mysql global_priv db tables_priv columns_priv procs_priv proxies_priv roles_mapping \
  > "$PRIV_DUMP"


# =======================
# 3) Stop and remove recovery mode
# =======================
log "Stopping MariaDB and removing recovery config"
stop_db
rm_recovery_cnf

# =======================
# 4) Rebuild a fresh datadir
# =======================
NEW_OLD_DIR="${BACKUP_ROOT}/datadir-pre-rebuild-${TS}"
log "Moving current datadir to $NEW_OLD_DIR (keeping your clean copy safe)"
mv "$DATADIR" "$NEW_OLD_DIR"
mkdir -p "$DATADIR"
chown mysql:mysql "$DATADIR"

log "Initializing new system tables"
$MARIADB_INSTALL_DB --user=mysql --basedir=/usr --datadir="$DATADIR"

log "Starting MariaDB normally"
start_db
wait_ready || { echo "FATAL: Fresh MariaDB failed to start." >&2; exit 3; }


log "Setting MySQL root password"
set +e
mysql --protocol=SOCKET -uroot <<'SQL'
SELECT VERSION();
SQL
IS_MARIADB=$?
set -e
# Preferred path for MariaDB 10.4+ (works on 10.11.x)
if mysql --protocol=SOCKET -uroot -e \
  "ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('${MYSQL_PWD}');"; then
  :
else
  # Fallbacks for older servers or edge configs
  # Try generic SET PASSWORD (MariaDB understands PASSWORD() function)
  if ! mysql --protocol=SOCKET -uroot -e \
    "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MYSQL_PWD}'); FLUSH PRIVILEGES;"; then
    # Old-style table update (MySQL 5.7 era). Won't run on MariaDB 10.4+, but kept as last resort.
    mysql --protocol=SOCKET -uroot -e \
      "UPDATE mysql.user SET plugin='mysql_native_password', Password=PASSWORD('${MYSQL_PWD}')
       WHERE User='root' AND Host='localhost'; FLUSH PRIVILEGES;"
  fi
fi

log "Restoring users"
PRIV_DUMP="${DUMPDIR}/_mysql_privileges.sql"
if [[ -s "$PRIV_DUMP" ]]; then
  log "Importing saved user accounts and grants (socket auth)"
  mysql --protocol=SOCKET -uroot mysql < "$PRIV_DUMP"
  mysql --protocol=SOCKET -uroot -e "FLUSH PRIVILEGES;"

  # Re-assert root plugin+password so passworded logins keep working
  mysql --protocol=SOCKET -uroot -e \
    "ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('${MYSQL_PWD}'); FLUSH PRIVILEGES;"

  # Sanity: passworded login
  mysql -uroot -p"${MYSQL_PWD}" -e "SELECT 1;"
else
  log "WARNING: No privilege dump found at $PRIV_DUMP; user accounts cannot be auto-restored."
fi


# =======================
# 5) Import dumps
# =======================
if compgen -G "$DUMPDIR/*.sql" > /dev/null; then
  log "Importing dumps"
  for f in "$DUMPDIR"/*.sql; do
    [[ "$(basename "$f")" == "_mysql_privileges.sql" ]] && continue
    log "  -> $(basename "$f")"
    $MYSQL < "$f"
  done
else
  log "No dumps were created; nothing to import."
fi

log "Done.

Backups:
  - Datadir backup:   $BK_DATADIR
  - Logs backup:      $BK_LOGDIR
  - Pre-rebuild dir:  $NEW_OLD_DIR
Dumps imported from:  $DUMPDIR

Next:
  * Verify: mysql -e 'SHOW DATABASES'
  * Consider ANALYZE/OPTIMIZE as needed
"
