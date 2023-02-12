Use Krescue to erase (full) the eMMC (otherwise you won't be able to boot from mSD): https://forum.khadas.com/t/krescue-take-full-control-of-your-vim-device-easy-way-to-install-any-os-back-restore-your-system/5945

To boot into Krescue, hold power button and don't let go while plugging in the USB power cable. Let go of power only after Krescue has booted. Use a USB keyboard to navigate the menu.


Create Debian base image with https://sd-card-images.johang.se/boards/khadas_vim3.html

Boot into that image.

Set the date of the dev board (required in order to use apt repositories):
https://baldnerd.com/nerdgasms/linuxdate/

`apt update`
`apt install ntp`

Wait for 10 minutes for time to catch up.

`apt update`

Prep and continue.





OLD:

You'll need the Khadas-provided 'utils' to image downloaded img files to the integrated eMMC.

Install the tools:

```
git clone https://github.com/khadas/utils
./INSTALL
```

Burn the img:

```
burn-tool -v aml -b VIM3 -i "file.img"
```

Create boot.png and convert with:

```
convert boot.png -type Palette -colors 224 -compress none -verbose BMP3:boot.bmp
```

Place in /boot
