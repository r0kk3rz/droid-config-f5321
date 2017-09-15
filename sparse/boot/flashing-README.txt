
= PRE STEPS FOR FLASHING ON TOP OF THE ANDROID BUILD =

If SONY Xperia X Compact is running Android you need to unlock bootloader before you can
flash Sailfish OS with these instructions. SONY has provided own instructions how
to unlock bootloader. You can follow instructions from here:

https://developer.sonymobile.com/unlockbootloader/unlock-yourboot-loader/


= FLASHING =

Before starting flashing on any host turn off the device. After this follow the
instructions given for your host PC operating system.

By this point of time you should already have the .tar.bz2 file that contains
the image as this flashing instructions file that you are reading at the moment
is inside that .tar.bz2 file. As a general note the flashing can take a long
time (>10 minutes) and it flashes image with similar name multiple times in the
end which is expected behaviour.


== LINUX ==

Open terminal application and go to the folder where the image is extracted.

Next:
* Connect device to computer with USB-cable while holding volume up button
* When you see constant blue LED, you can release the volume up button.
* Next start flashing script by entering following command:

  bash ./flash.sh

* Enter your password if requested to gain root access for flashing the device
* Once flashing is completed you will see text: 

  "Flashing completed. Detact usb cable, press and hold the powerkey to reboot."

* After following the guidance from script device should boot up to new Sailfish OS

NOTE: If flashing does not succeed, you might have missing fastboot binary or
it is too old. Many distros include andoid-tools package, but that might not
be new enough to support Xperia X Compact flashing.

Installation commands for some linux distributions:
* Ubuntu: sudo apt-get install android-tools-fastboot

If you want to compile fastboot binary for your distro you can compile version
5.1.1 release 38 or newer from:
https://github.com/mer-qa/qa-droid-tools

