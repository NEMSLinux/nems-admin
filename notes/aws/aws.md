Deploy Debian Buster AMI from the AWS Marketplace, with Free Tier available. Place on Micro instance where Free Tier is available.

Prep as normal.

Create a prepped image and terminate the previous instance.

Creating a new instance based on the snapshot, but:

set the storage size to 16GB (Free tier compatibility is up to 30).

add this to the user data field (under advanced, far bottom):

```
#cloud-config
system_info:
  default_user:
    name: nemsadmin
```

Compile NEMS as normal.

Clean & Halt, and create the AMI.
