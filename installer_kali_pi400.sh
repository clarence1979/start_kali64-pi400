xfconf-query -c xfwm4 -p /general/use_compositing -s false
xfwm4 --replace &

sudo sed -i '$s/.*/managed=true/' /etc/NetworkManager/NetworkManager.conf
sudo bash -c 'echo -e "\nauto eth0\niface eth0 inet dhcp\n\nauto eth1\niface eth1 inet dhcp" >> /etc/network/interfaces'


sudo sed -i "/^nameserver 8.8.8.8/d" "/etc/resolv.conf"
sudo sed -i "/^nameserver 8.8.4.4/d" "/etc/resolv.conf"

sudo chattr +i /etc/resolv.conf

sudo systemctl enable bluetooth
sudo systemctl start bluetooth

sudo systemctl restart networking
service network-manager restart

sudo apt-get update -y && sudo apt full-upgrade -y 
sudo apt-get install gedit -y
sudo apt-get install idle -y
sudo apt-get install libreoffice -y


sudo rm -rf /var/lib/apt/lists/* 
cd ~
cd /home/kali/ 
echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections

sudo apt-get install wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg


sudo apt install apt-transport-https
sudo apt update
sudo apt install code # or code-insiders
sudo pip install ipykernel --break-system-packages

cd ~
cd /home/kali/Desktop
git clone https://github.com/htr-tech/zphisher.git
cd zphisher
sudo bash ./install.sh

