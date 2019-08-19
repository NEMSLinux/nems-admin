Key point is that NEMS' Docker Container requires systemd, but as that would pose a security risk, I have opted to instead go with docker-systemctl-replacement. I've setup an environment that should behave much like a virtual appliance.

  - Run in image folder: `docker build -t nemslinux .`
  - Get the Docker ID: Note the output of "Successfully built ####"
  - Run the container as daemon: `docker run --mount type=tmpfs,destination=/tmp,tmpfs-mode=1770 --name nemslinux -d ##DOCKERID##`
#  - Connect to the container: `docker run -it ##DOCKERID## bash`
  - Connect to the container: `docker exec -it nemslinux bash`
  - Compile NEMS Linux as normal, platform 21.
  - Run NEMS Linux: `docker exec -d nemslinux`

##How to operate

  - nemslinux must first be running as daemon: `docker run -d nemslinux`
  - To access terminal of NEMS Server: `docker exec -it nemslinux bash`
