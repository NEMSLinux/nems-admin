Key point is that NEMS' Docker Container requires systemd, but as that would pose a security risk, I have opted to instead go with docker-systemctl-replacement. I've setup an environment that should behave much like a virtual appliance.

  - Run in image folder: `./compile`
  - Deploy the container as daemon: `docker run --mount type=tmpfs,destination=/tmp,tmpfs-mode=1770 --restart=unless-stopped --stop-timeout 120 --name nems -d nemslinux`
  - Connect to the container: `docker exec -it nemslinux bash`
  - Compile NEMS Linux as normal, platform 21.
  - Run NEMS Linux: `docker exec -d nemslinux`
