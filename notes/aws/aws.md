When creating the instance, add this to the user data field:

#cloud-config
system_info:
  default_user:
    name: nemsadmin


Boot once, then clean, shut down and create the AMI.
