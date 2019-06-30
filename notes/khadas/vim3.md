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
