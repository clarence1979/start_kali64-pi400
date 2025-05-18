sudo systemctl stop mariadb
sudo apt purge mariadb-server mariadb-client mariadb-common -y
sudo apt autoremove --purge -y
sudo rm -rf /etc/mysql /var/lib/mysql /var/log/mysql /var/run/mysqld
sudo apt update
sudo apt install mariadb-server -y
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo systemctl status mariadb

