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
apt install -y network-manager nm-tray bluetooth bluez blueman volumeicon

echo "Installing PCManFM and archive tools..."
apt install -y pcmanfm gvfs file-roller p7zip-full unzip

echo "Installing desktop utilities: feh, diodon, dunst, picom..."
apt install -y feh diodon dunst picom xtrlock xfce4-power-manager

echo "Installing additional apps: qutebrowser, arandr, rofi..."
apt install -y qutebrowser arandr rofi lxtask lxappearance scite

echo "Installing Papirus icon theme..."
apt install -y papirus-icon-theme

echo "Creating .xsession..."
cat > "/home/$USERNAME/.xsession" <<EOF
#!/bin/sh
xinput --map-to-output "FTSC1000:00 2808:1015" DSI1
picom --backend xrender &
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

echo "Adding user to sudo group..."
usermod -aG sudo "$USERNAME"

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
