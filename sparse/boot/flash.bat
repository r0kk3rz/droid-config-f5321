@echo off

:: This is simple windows flashing script for Sony Xperia X device
:: This script is using fastboot to flash which differs from the factory method.

set tmpflashfile=tmpfile.txt

del %tmpflashfile% >NUL 2>NUL

echo Power on the device in fastboot mode, by doing following.
echo 1. Turn off the device.
echo 2. Hold volume up button while plugging in the USB cable to your PC
echo 3. After this you should see blue LED
pause
call :sleep 3

:: Bus 002 Device 025: ID 0fce:0dde Sony Ericsson Mobile Communications AB Xperia Mini Pro Bootloader
set vendorid=0x0fce
set fastbootcmd=fastboot.exe -i %vendorid%

echo Searching device with vendor id '%vendorid%'..
start /b cmd /c %fastbootcmd% getvar product 2^>^&1 ^| find "product:" ^> %tmpflashfile%
call :sleep 3
:: In case the device is not online, fastboot will just hang forever thus
:: kill it here so the script ends at some point.
taskkill /im fastboot.exe /f >NUL 2>NUL
:: F5121 - Xperia X
:: F5122 - Xperia X Dual SIM
:: F5321 - Xperia X Compact
:: TODO: Verify that this works
findstr /R /C:"product: F5[13]2[12]" %tmpflashfile%
if not errorlevel 1 GOTO no_error

echo The DEVICE this flashing script is meant for WAS NOT FOUND!
echo You might be missing the required drivers for your phone.
echo Go to Device Manager and update the fastboot driver from
echo android_winusb.inf file.
pause
exit /b 1

:no_error

del %tmpflashfile% >NUL 2>NUL

:: We want to print the fastboot commands so user can see what actually
:: happens when flashing is done.
@echo on

@call :fastboot flash boot hybris-boot.img
@call :fastboot flash system fimage.img001
@call :fastboot flash userdata sailfish.img001

:: NOTE: Do not reboot here as the battery might not be in the device
:: and in such situation we should not reboot the device.
@echo Flashing completed. Remove the USB cable and bootup the device by pressing powerkey.
@pause

@exit /b 0

:: Function to sleep X seconds
:sleep
@echo "Waiting %*s.."
ping 127.0.0.1 -n %* >NUL
@exit /b 0

:md5sum
:: Before flashing calculate md5sum to ensure file is not corrupted
@for /f "delims=" %%i in ('findstr %~1 md5.lst') do @set md5sumold=%%i
:: We want to take the second line of output from CertUtil, if you know better way let me know :)
@for /f "skip=1 tokens=1 delims=" %%i in ('CertUtil -hashfile %~1 MD5') do @set md5sumnew=%%i && goto :file_break
:file_break
:: Drop all spaces from the md5sumnew as the format provided by CertUtil is two chars space two chars..
@set md5sumnew=%md5sumnew: =%
:: Drop everything after the first pace in md5sumold
@set "md5sumold=%md5sumold: ="&rem %
@IF NOT "%md5sumnew%" == "%md5sumold%" (
  @echo MD5SUM of file %~1 does not match to md5.lst.
  @call :exitflashfail
)
@echo MD5SUM '%md5sumnew%' match for %~1.
@exit /b 0

:: Function to call fastboot command with error checking
:fastboot
:: When flashing check md5sum of files
@IF "%~1" == "flash" (
  @call :md5sum %~3
)
%fastbootcmd% %*
@IF "%ERRORLEVEL%" == "1" (
  @echo ERROR: Failed to execute '%fastbootcmd% %*'.
  @call :exitflashfail
)
@exit /b 0

:exitflashfail
@echo FLASHING FAILED!
@echo Please contact party who provided this image to you.
pause
@exit 1
@exit /b 0

