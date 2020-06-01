Key point is that NEMS' Docker Container requires systemd, but as that would pose a security risk, I have opted to instead go with docker-systemctl-replacement. I've setup an environment that should behave much like a virtual appliance.

  - Build the image, compile NEMS Linux, and deploy: `./compile`
  - Connect to the container: `docker exec -it nemslinux bash`

Publish to DockerHub:

  - Stop the container: `docker stop nemslinux`
  - `docker tag nems_1.5.2 baldnerd/nemslinux:1.5.2_build1`
  - `docker login && docker push baldnerd/nemslinux:1.5.2_build1`
  
Publish to Downloadable File:

  - Stop the container: `docker stop nemslinux`
  - docker save -o nemslinux.docker nemslinux

Install from Downloadable File:

  - docker load -i nemslinux.docker
  - Follow normal install instructions in Docs (Docker will use your local copy now, rather than the one from DockerHub).

Deploy (Install):

  - See [[https://docs.nemslinux.com/supported_platforms/docker|Docs]].

Start/Stop NEMS Linux:

`docker start nemslinux`

or

`docker stop nemslinux`

Initialize:

`docker exec -it nemslinux nems-init`
