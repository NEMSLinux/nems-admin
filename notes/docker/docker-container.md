Key point is that NEMS' Docker Container requires systemd, but as that would pose a security risk, I have opted to instead go with docker-systemctl-replacement. I've setup an environment that should behave much like a virtual appliance.

  - Build the image and compile NEMS Linux: `./compile`
  - Deploy the container as daemon: `docker run --hostname nems --mount type=tmpfs,destination=/tmp,tmpfs-mode=1777 --mount type=tmpfs,destination=/var/www/html/backup/snapshot,tmpfs-mode=1770 --restart=unless-stopped --stop-timeout 120 --name nemslinux -d nems_1.5`
  - Connect to the container: `docker exec -it nemslinux bash`
  - Compile NEMS Linux as normal, platform 21.
  - Run NEMS Linux: `docker exec -d nemslinux`

Publish when ready:

  - Stop the container: `docker stop nemslinux`
  - `docker tag nems_1.5 baldnerd/nemslinux:1.5_build1`
  - `docker login && docker push baldnerd/nemslinux:1.5_build1`
  
Deploy:

`docker run --hostname nems --mount type=tmpfs,destination=/tmp,tmpfs-mode=1777 --mount type=tmpfs,destination=/var/www/html/backup/snapshot,tmpfs-mode=1770 --restart=unless-stopped --stop-timeout 120 --name nemslinux -d baldnerd/nemslinux:1.5_build1`
