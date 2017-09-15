%define rpm_device f5321
%define rpm_vendor qualcomm

%define vendor_pretty Sony
%define device_pretty Xperia X Compact

# Sailfish OS is considered to-scale, if in app grid you get 4-in-a-row icons
# and 2x2 or 3x3 covers when up-to-4 or 5-or-more apps are open respectively.
# For 4-5.5" device screen sizes of 16:9 ratio, use this formula (hold portrait):
# pixel_ratio = 4.5/DiagonalDisplaySizeInches * HorizontalDisplayResolution/540
# Other screen sizes and ratios will require more trial-and-error.
%define pixel_ratio 1.3

%define out_of_image_files 1
%define provides_own_board_mapping 1

# Device-specific ofono configuration
Provides: ofono-configs

# Device-specific usb-moded configuration
Provides: usb-moded-configs

%include droid-configs-device/droid-configs.inc

