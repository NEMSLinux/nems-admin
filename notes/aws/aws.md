Deploy Debian Buster AMI from the AWS Marketplace, with Free Tier available. Place on Micro instance where Free Tier is available.

Prep as normal.

Create a prepped image and terminate the previous instance.

Creating a new instance based on the snapshot, but add this to the user data field:

```
#cloud-config
system_info:
  default_user:
    name: nemsadmin
```

Compile NEMS as normal.

Clean & Halt, and create the AMI.
