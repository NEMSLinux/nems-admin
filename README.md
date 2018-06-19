# nems-admin
Admin scripts for NEMS

These are used by Robbie to assist with development of NEMS. None of these scripts are designed for end-users (and in fact can cause a lot of damage - so please understand what you're doing before running anything in here).

If you build a custom build of NEMS Linux, please contact Robbie so he can help customize the system (otherwise it will show up as an unknown device and will not present accurate information).

Install Debian on your hardware with the following settings:
- Hostname: nems-*YOURDEVICE* - for example nems-pi for a Raspberry Pi.
- Root password: nemsadmin
- Base user username: nemsadmin
- Base user password: nemsadmin

- Prep the clean Debian install for NEMS deployment (as root):
```bash
apt update && apt install -y ca-certificates wget && wget -O /tmp/nems-prep.sh https://raw.githubusercontent.com/Cat5TV/nems-admin/master/nems-prep.sh && chmod +x /tmp/nems-prep.sh && /tmp/nems-prep.sh
```

- Convert Debian to NEMS Linux (as root):
```bash
/root/nems/nems-admin/nems-build.sh
```

- Reboot
- Go about testing/configuring your system.
- Migrate data to /root/nems/nems-migrator/data folder where applicable. Note: If done unofficially, you will break nems-migrator's ability to update itself from the official repository.
- Run nems-cleanup.sh to remove confidential data and restore all settings to defaults (from nems-migrator), preparing your NEMS build for distribution.

This is 100% destructive. NEVER run this on an existing system. This is for new builds ONLY (eg., porting NEMS to a new piece of hardware).

If you are a hardware vendor using this to test if NEMS will function on your hardware, please contact me to discuss making an official build for your hardware. All you need to do is send a device, spec information, and we'll get working on a custom, official build.

More information at https://nemslinux.com
