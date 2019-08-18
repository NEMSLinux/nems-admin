Create the Debian container: `nemsid=$(docker run -dit debian) && docker rename $nemsid nemslinux`
Connect to the container: `docker exec -it nemslinux bash`

Prep.
