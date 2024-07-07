echo "----------------------------------------"
echo "-- ARCH INSTALLER BY ORBITAL TRAVELER --"
echo "----------------------------------------"

echo "Make sure you have a working internet connection"
echo "This script will install Arch Linux on your system"
echo "Please make sure you have at least peritioned EFI and ROOT paritition"
echo -e "If you haven't done that, please do that first and then run this script\n\n"


timedatectl set-ntp true

echo "Please enter EFI paritition: (example /dev/sda1 or /dev/nvme0n1p1)"
read EFI

echo "Please enter Root(/) paritition: (example /dev/sda2)"
read ROOT 

echo "Do you have SWAP partition? (y/n)"
read SWAPQ

if [[ $SWAPQ == 'y' ]]
then
  echo "Please enter SWAP paritition: (example /dev/sda3)"
  read SWAP
else
  :
fi

echo "Please enter your username"
read USER 

echo "Please enter your password"
read PASSWORD 

echo "Enter password for root"
read ROOTPASSWORD

echo "Please enter your hostname"
read HOSTNAME

# make filesystems
echo -e "\nCreating Filesystems...\n"

mkfs.vfat -F32 "${EFI}"
if [[ $SWAPQ == 'y' ]]
then
  mkswap "${SWAP}"
  swapon "${SWAP}"
fi
mkfs.ext4 "${ROOT}"

# mount target
mount "${ROOT}" /mnt
mkdir /mnt/efi
mount "${EFI}" /mnt/efi

pacstrap /mnt base linux linux-firmware

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt
pacman -Syu iwd netctl dialog dhcpcd wpa_supplicant ifplugd sudo neovim grub efibootmgr neofetch  networkmanager 
EDITOR=nvim


useradd -G wheel,storage,power,audio -m $USER
echo $USER:$PASSWORD | chpasswd
echo root:$ROOTPASSWORD | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers


sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

grub-install --target=x86_64-efi --efi-directory=/efi/ --bootloader-id=Arch
grub-mkconfig -o /boot/grub/grub.cfg

echo $HOSTNAME > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1  $HOSTNAME.localdomain $HOSTNAME
EOF

cat <<EOF > /etc/systemd/network/10-wired.network
[Match]
Name=en*

[Network]
DHCP=ipv4

[DHCP]
RouteMetric=10
EOF

cat <<EOF > /etc/systemd/network/10-wireless.network
[Match]
Name=wlp*

[Network]
DHCP=ipv4

[DHCP]
RouteMetric=20
EOF

cat <<EOF > /etc/iwd/main.conf
[General]
EnableNetworkConfiguration=true

[Network]
NameResolvingService=systemd
EOF

systemctl enable iwd
systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable NetworkManager

echo "-- INSTALLATION COMPLETE --"
echo "-- REBOOTING IN 5 SECONDS --"
sleep 5
reboot

REALEND


arch-chroot /mnt

