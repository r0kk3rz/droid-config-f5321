
= PRE STEPS FOR FLASHING ON TOP OF THE ANDROID BUILD =

If your SONY Xperia X is running Android you need to unlock bootloader before you can
flash Sailfish OS to it. SONY has provided own instructions how
to unlock bootloader. Please follow those instructions in here:

https://developer.sonymobile.com/unlockbootloader/unlock-yourboot-loader/

It is best to first update the Android delivery on your Xperia device. For this you
need to download the Emma tool from Sony's website and follow instructions given
on that website.

https://developer.sonymobile.com/open-devices/flash-tool/how-to-download-and-install-the-flash-tool/

NOTE: Currently Sony provides Emma tool just for Windows.

The needed Android version is 34.3 or newer. Version string format: x-x_34.3.x.x.x


= FLASHING =

By this point of time you should already have the .zip file that contains
the image as this flashing instructions file that you are reading at the moment
is inside that .zip file. As a general note the flashing can take a long
time (>10 minutes).

Before starting the flashing:
* Disconnect your Xperia device from your PC
* Turn off your Xperia device
* Connect one end of a USB cable to your PC
* While holding the volume up button pressed, connect the other end of the USB
  cable to your Xperia device.
* After this you should see the blue LED lit on the Xperia device, and it is
  ready for flashing.

After this follow the instructions given for your host PC operating system.


== WINDOWS 7/8/10 ==

NOTE: In order to flash in windows the device needs to be detected properly.
This might take a while and after it is done there should be adb or fastboot device
shown in Windows Device Manager.

Open e.g. Windows Explorer and go to the folder where the image is extracted.

Next start the flashing script by double clicking the flash.bat file

NOTE: Windows by default hides the .bat file so it might be shown just as
      flash file in e.g. Windows Explorer.

NOTE: If you see notification "Windows protected your PC", click
      "More info" and then "Run anyway"

Follow the instructions on the screen while flashing script is running.

After completing the flash.bat script you can enjoy your Sailfish OS on Xperia.

== LINUX ==

Open terminal application and go to the folder where the flashable image is
extracted.

Next:
* Next start flashing script by entering following command:

  bash ./flash.sh

* Enter your password if requested to gain root access for flashing the device
* Once flashing is completed you will see text: 

  "Flashing completed. Detact usb cable, press and hold the powerkey to reboot."

* After following the guidance from script device should boot up to new Sailfish OS

NOTE: If flashing does not succeed, you might have missing fastboot binary or
it is too old. Many distros include andoid-tools package, but that might not
be new enough to support Xperia X flashing.

Installation commands for some linux distributions:
* Ubuntu: sudo apt-get install android-tools-fastboot
* Fedora: sudo dnf install android-tools

If you want to compile fastboot binary for your distro you can compile version
5.1.1 release 38 or newer from:
https://github.com/mer-qa/qa-droid-tools

