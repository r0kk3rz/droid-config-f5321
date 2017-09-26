@echo off

:: This is simple windows flashing script for Sony Xperia X device
:: This script is using fastboot to flash which differs from the factory method.

set tmpflashfile=tmpfile.txt
set emmawebsite=https://developer.sonymobile.com/open-devices/flash-tool/how-to-download-and-install-the-flash-tool/

echo(
echo Power on the device in fastboot mode, by doing following.
echo 1. Turn off the device.
echo 2. Hold volume up button while plugging in the USB cable to your PC
echo 3. After this you should see blue LED
echo(
pause
call :sleep 3

:: Bus 002 Device 025: ID 0fce:0dde Sony Ericsson Mobile Communications AB Xperia Mini Pro Bootloader
set vendorid=0x0fce
set fastbootcmd=fastboot.exe -i %vendorid%

echo Searching device with vendor id '%vendorid%'..

:: Ensure that we are flashing right device
:: F5121 - Xperia X
:: F5122 - Xperia X Dual SIM
:: F5321 - Xperia X Compact
@call :getvar product
findstr /R /C:"product: F5[13]2[12]" %tmpflashfile% >NUL 2>NUL
if not errorlevel 1 GOTO no_error

echo(
echo The DEVICE this flashing script is meant for WAS NOT FOUND!
echo You might be missing the required drivers for your phone.
echo Go to Device Manager and update the fastboot driver from provided
echo android_winusb.inf file.
echo(
pause
exit /b 1

:no_error

:: Verify that the sony release on the phone is new enough.
@call :getvar version-baseband

:: Take from 1300-4911_34.0.A.2.292 the first number set, e.g., 34.0
for /f "tokens=2 delims=_" %%i in ('type %tmpflashfile%') do @set version1=%%i
for /f "tokens=1-2 delims=." %%a in ('echo %version1%') do @set version2=%%a.%%b

:: We only support devices that have been flashed at least with version 34.0 of the Sony AOSP delivery
if %version2% LSS 34.3 (
echo(
echo You have too old Sony AOSP version on your device, 
echo please go to %emmawebsite% and update your device.
echo Press enter to open the browser with the webpage.
echo(
pause
start "" %emmawebsite%
exit /b 1
)

del %tmpflashfile% >NUL 2>NUL

:: We want to print the fastboot commands so user can see what actually
:: happens when flashing is done.
@echo on

@call :fastboot flash boot hybris-boot.img
@call :fastboot flash system fimage.img001
@call :fastboot flash userdata sailfish.img001

:: NOTE: Do not reboot here as the battery might not be in the device
:: and in such situation we should not reboot the device.
@echo(
@echo Flashing completed. Remove the USB cable and bootup the device by pressing powerkey.
@pause

@exit /b 0

:: Function to sleep X seconds
:sleep
:: @echo "Waiting %*s.."
ping 127.0.0.1 -n %* >NUL
@exit /b 0

:getvar
del %tmpflashfile% >NUL 2>NUL

start /b cmd /c %fastbootcmd% getvar %* 2^>^&1 ^| find "%*:" ^> %tmpflashfile%
call :sleep 3
:: In case the device is not online, fastboot will just hang forever thus
:: kill it here so the script ends at some point.
taskkill /im fastboot.exe /f >NUL 2>NUL
@exit /b 0

:md5sum
:: Before flashing calculate md5sum to ensure file is not corrupted, so for each line in md5.lst do
@for /f %%i in ('findstr %~1 md5.lst') do @set md5sumold=%%i
:: We want to take the second line of output from CertUtil, if you know better way let me know :)
@for /f "skip=1 tokens=1" %%i in ('CertUtil -hashfile %~1 MD5') do @set md5sumnew=%%i && goto :file_break
:file_break
:: Drop all spaces from the md5sumnew as the format provided by CertUtil is two chars space two chars..
@set md5sumnew=%md5sumnew: =%
:: Drop everything after the first space in md5sumold
@set "md5sumold=%md5sumold: ="&rem %
@IF NOT "%md5sumnew%" == "%md5sumold%" (
  @echo(
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
  @echo (
  @echo ERROR: Failed to execute '%fastbootcmd% %*'.
  @call :exitflashfail
)
@exit /b 0

:exitflashfail
@echo (
@echo FLASHING FAILED!
@echo Please contact party who provided this image to you.
pause
@exit 1
@exit /b 0

