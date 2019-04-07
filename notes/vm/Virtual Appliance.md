OVA:

- ~~Deploy as normal using VHD as the drive type within VirtualBox, export as OVA will convert to VMDK within OVA.~~
- Deploy on ESXi, export to OVF/VMDK.
- On a Windows machine, use OVF tool https://my.vmware.com/group/vmware/details?downloadGroup=OVFTOOL430&productId=742
  - "C:\Program Files\VMware\VMware OVF Tool\ovftool.exe" --noSSLVerify "vi://root@10.0.0.105/NEMS Linux" NEMS.ova

VHD:

- ~~Copy from dev master which was used to create OVA.~~
- On Windows, use Microsoft Virtual Machine Converter - https://www.microsoft.com/en-ca/download/details.aspx?id=42497

QCOW2:
- Extract VMDK from OVA.
- On Linux, install qemu-utils
- Convert: qemu-img convert -f vmdk -O qcow2 nems.vmdk nems.qcow2
