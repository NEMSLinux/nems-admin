  - Run in image folder: `docker build -t nemslinux .`
  - Get the Docker ID: Note the output of "Successfully built ####"
  - Run the container as daemon: `docker run --name nemslinux -d ##DOCKERID##`
#  - Connect to the container: `docker run -it ##DOCKERID## bash`
  - Connect to the container: `docker exec -it nemslinux bash`
  - Compile NEMS Linux as normal, platform 21.
  - Run NEMS Linux: `docker exec -d nemslinux`
