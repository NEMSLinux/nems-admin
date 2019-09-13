Key point is that NEMS' Docker Container requires systemd, but as that would pose a security risk, I have opted to instead go with docker-systemctl-replacement. I've setup an environment that should behave much like a virtual appliance.

  - Build the image, compile NEMS Linux, and deploy: `./compile`
  - Connect to the container: `docker exec -it nemslinux bash`

Publish when ready:

  - Stop the container: `docker stop nemslinux`
  - `docker tag nems_1.5 baldnerd/nemslinux:1.5_build1`
  - `docker login && docker push baldnerd/nemslinux:1.5_build1`
  
Deploy (Install):

`docker run --hostname nems --mount type=tmpfs,destination=/tmp,tmpfs-mode=1777 --mount type=tmpfs,destination=/var/www/html/backup/snapshot,tmpfs-mode=1770 --restart=unless-stopped --stop-timeout 120 --name nemslinux -d -p 80:80 -p 443:443 -p 2812:2812 baldnerd/nemslinux:1.5.1_build1`

Start/Stop NEMS Linux:

`docker start nemslinux`

or

`docker stop nemslinux`

Initialize:

`docker exec -it nemslinux nems-init`
