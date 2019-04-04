OVA:
~~- Deploy as normal using VHD as the drive type within VirtualBox, export as OVA will convert to VMDK within OVA.~~
- Deploy on vSphere, output to OVA.

VHD:
~~- Copy from dev master which was used to create OVA.~~
- On Windows, use Microsoft Virtual Machine Converter - https://www.microsoft.com/en-ca/download/details.aspx?id=42497

QCOW2:
- Extract VMDK from OVA.
- On Linux, install qemu-utils
- Convert: qemu-img convert -f vmdk -O qcow2 nems.vmdk nems.qcow2
