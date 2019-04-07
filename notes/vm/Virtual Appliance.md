OVA:

- ~~Deploy as normal using VHD as the drive type within VirtualBox, export as OVA will convert to VMDK within OVA.~~
- Deploy on ESXi.
- On a Windows machine, use OVF tool https://my.vmware.com/group/vmware/details?downloadGroup=OVFTOOL430&productId=742
  - "C:\Program Files\VMware\VMware OVF Tool\ovftool.exe" --noSSLVerify "vi://root@10.0.0.105/NEMS Linux" NEMS.ova

VHD:

- ~~Copy from dev master which was used to create OVA.~~
- Extract VMDK file from OVA.
- Using [vmdk2vhd](https://www.softpedia.com/get/System/File-Management/Vmdk2Vhd.shtml) convert the file.

QCOW2:
- Extract VMDK from OVA.
- On Linux, install qemu-utils
- Convert: qemu-img convert -f vmdk -O qcow2 nems.vmdk nems.qcow2
