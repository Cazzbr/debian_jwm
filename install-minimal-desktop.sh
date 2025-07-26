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
apt install -y xorg xinit jwm xterm

echo "Installing network and Bluetooth tools..."
apt install -y network-manager nm-tray bluetooth bluez blueman

echo "Installing LY login manager..."
apt install -y ly

echo "Installing PCManFM and archive tools..."
apt install -y pcmanfm gvfs file-roller p7zip-full unzip

echo "Installing desktop utilities: feh, parcellite, dunst, picom..."
apt install -y feh parcellite dunst picom

echo "Installing additional apps: qutebrowser, arandr, rofi..."
apt install -y qutebrowser arandr rofi

echo "Installing Papirus icon theme..."
apt install -y papirus-icon-theme

echo "Creating .xinitrc..."
cat > "/home/$USERNAME/.xinitrc" <<EOF
picom --experimental-backends --fade-in-step=1.0 --fade-out-step=1.0 &
nm-tray &
blueman-applet &
parcellite &
dunst &
feh --bg-scale /usr/share/backgrounds/desktop.jpg &
exec jwm
EOF
chown "$USERNAME:$USERNAME" "/home/$USERNAME/.xinitrc"

echo "Adding user to sudo group..."
usermod -aG sudo "$USERNAME"

echo "Setting passwordless reboot/poweroff for $USERNAME..."
echo "$USERNAME ALL=(ALL) NOPASSWD: /bin/systemctl reboot, /bin/systemctl poweroff" >> /etc/sudoers.d/99-nopasswd-reboot

echo "Copying custom JWM configuration..."
mkdir -p "/home/$USERNAME/.jwm"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
cp "$SCRIPT_DIR/jwmrc" "/home/$USERNAME/.jwm/jwmrc"
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.jwm"
echo "Custom theme applied."

echo "Enabling services..."
systemctl enable ly
systemctl enable NetworkManager
systemctl enable bluetooth

echo "Cleaning legacy network config..."
if [ -f /etc/network/interfaces ]; then
  cp /etc/network/interfaces /etc/network/interfaces.backup
  echo -e "auto lo\niface lo inet loopback" > /etc/network/interfaces
fi
if [ -f /etc/wpa_supplicant/wpa_supplicant.conf ]; then
  mv /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf.backup
fi

echo "✅ Setup complete! Reboot to enjoy your personalized desktop."
