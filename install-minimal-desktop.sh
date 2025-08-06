#!/bin/bash

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root."
  exit 1
fi

USERNAME=$(logname)

echo "Updating system..."
apt update && apt upgrade -y

echo "Installing graphical system and core tools..."
apt install -y xorg xinit jwm xterm xinput

echo "Installing network and Bluetooth tools..."
apt install -y network-manager nm-tray bluetooth bluez blueman volumeicon-alsa

echo "Installing PCManFM and archive tools..."
apt install -y pcmanfm gvfs file-roller p7zip-full unzip

echo "Installing desktop utilities: feh, diodon, dunst, picom..."
apt install -y feh diodon dunst picom xtrlock xfce4-power-manager

echo "Installing additional apps: falkon, arandr, rofi..."
apt install -y falkon arandr rofi lxtask lxappearance scite onboard

echo "Installing Papirus icon theme..."
apt install -y papirus-icon-theme

echo "Creating .xsession..."
cat > "/home/$USERNAME/.xsession" <<EOF
#!/bin/sh
xinput --map-to-output "FTSC1000:00 2808:1015" DSI1
picom &
nm-tray &
blueman-applet &
volumeicon &
xfce4-power-manager &
diodon &
dunst &
feh --bg-scale /usr/share/backgrounds/desktop.jpg &
exec jwm
EOF
chown "$USERNAME:$USERNAME" "/home/$USERNAME/.xsession"

echo "Creating .Xresources..."
cat > "/home/$USERNAME/.Xresources" <<EOF
! Sample `.Xresources` file for (new) XTerm users
! TIP: If you are new to XTerm and have not modified your system Xresources, follow these initial instructions:
! 1. Download and save this file as `.Xresources` to your user home directory (`~/.Xresources`).
! 2. Run `$ xrdb -merge ~/.Xresources`.
! 3. Open a new XTerm window. You can run `$ xterm &`.
! NOTE: To view the applied contents of this file, run `$ xrdb -query`.
! IMPORTANT:
! If you update the value on any line in this file, run `$ xrdb -merge ~/.Xresources` to apply the update.
! If you un/comment or add/remove one or more lines in this file (like when trying a different color theme),
! run `$ xrdb -remove` to clear all resources, and then run `$ xrdb -merge ~/.Xresources` to apply the update.

! Window title

xterm*Title: XTerm

! Window dimensions

xterm*geometry: 106x54
! example: 106x54 (for 15-inch laptops)
! TIP: To conveniently determine your desired terminal window size for XTerm startup,
! resize an XTerm window to the desired size and then run '$ resize' in it or see 'man resize'.
xterm*internalBorder: 2

! Typeface

! xterm*faceName: Monospace Regular
xterm*faceName: AdwaitaMono Nerd Font Mono
xterm*faceSize: 11
xterm*boldMode: false

! Color theme

! DOSBox
! https://github.com/xterm-x11/files.Xresources/blob/main/XTerm-color-theme-registry/0001.Xresources
xterm*foreground: rgb:a8/a8/a8
xterm*background: rgb:00/00/00
xterm*color0: rgb:00/00/00
xterm*color1: rgb:a8/00/00
xterm*color2: rgb:00/a8/00
xterm*color3: rgb:a8/54/00
xterm*color4: rgb:00/00/a8
xterm*color5: rgb:a8/00/a8
xterm*color6: rgb:00/a8/a8
xterm*color7: rgb:a8/a8/a8
xterm*color8: rgb:54/54/54
xterm*color9: rgb:fc/54/54
xterm*color10: rgb:54/fc/54
xterm*color11: rgb:fc/fc/54
xterm*color12: rgb:54/54/fc
xterm*color13: rgb:fc/54/fc
xterm*color14: rgb:54/fc/fc
xterm*color15: rgb:fc/fc/fc

! History and scrolling

xterm*saveLines: 10000
xterm*scrollBar: false
xterm*scrollLines: 1

! Copy-paste

XTerm.vt100.selectToClipboard: true
EOF
chown "$USERNAME:$USERNAME" "/home/$USERNAME/.Xresources"

echo "Setting passwordless reboot/poweroff for $USERNAME..."
echo "$USERNAME ALL=(ALL) NOPASSWD: /bin/systemctl reboot, /bin/systemctl poweroff" >> /etc/sudoers.d/99-nopasswd-reboot

echo "Copying custom JWM configuration..."
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
cp "$SCRIPT_DIR/.jwmrc" "/home/$USERNAME/.jwmrc"
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.jwmrc"
echo "Custom theme applied."

echo "Cleaning legacy network config..."
if [ -f /etc/network/interfaces ]; then
  cp /etc/network/interfaces /etc/network/interfaces.backup
  echo -e "auto lo\niface lo inet loopback" > /etc/network/interfaces
fi
if [ -f /etc/wpa_supplicant/wpa_supplicant.conf ]; then
  mv /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf.backup
fi

echo "✅ Setup complete! Reboot to enjoy your personalized desktop."
