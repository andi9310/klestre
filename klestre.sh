#!/bin/bash


#deb packages

sudo apt-get update ;
sudo apt-get install tftpd-hpa syslinux initramfs-tools nfs-kernel-server build-essential module-assistant isc-dhcp-server ;


#dhcp server

sudo mv /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak ;
echo 'allow booting;
allow bootp;
subnet 192.168.0.0 netmask 255.255.255.0 {
 range 192.168.0.100 192.168.0.200;
 default-lease-time 86400;
 option domain-name "kick.lan";
 option domain-name-servers 192.168.0.1;
 option routers 192.168.0.1;
 option subnet-mask 255.255.255.0;
 option broadcast-address 192.168.0.255;
 filename "/pxelinux.0";
}' | sudo tee -a /etc/dhcp/dhcpd.conf ;
echo 'auto eth1
iface eth1 inet static
address 192.168.0.1
netmask 255.255.255.0
network 192.168.0.0
broadcast 192.168.0.255
gateway 192.168.0.1
dns-nameservers 192.168.0.1' | sudo tee -a /etc/network/interfaces ;
sudo ifconfig eth1 down ;
sudo ifconfig eth1 up ;
sudo service isc-dhcp-server restart ;


#nfs - for kickstart (do we need it?)

sudo mkdir /share ;
sudo chmod 777 /share ;
echo '/share 192.168.0.*(rw,nohide,insecure,no_subtree_check,async,no_root_squash)' | sudo tee -a /etc/exports ;
sudo exportfs -ra ;
sudo echo 'rpcbind mountd nfsd statd lockd rquotad : 192.168.0.*' | sudo tee -a /etc/hosts.allow ;
sudo echo 'ALL: 127.0.0.1' | sudo tee -a /etc/hosts.allow ;
sudo service nfs-kernel-server restart ;


#routing workarounds - TODO - add it permanently (at startup?)

sudo /sbin/route del default ;
sudo /sbin/route add default gw 10.0.2.2 eth0 ;


#tftp - for pxe

echo '#Defaults for tftpd-hpa
RUN_DAEMON="yes"
OPTIONS="-l -s /tftpboot"' | sudo tee /etc/default/tftpd-hpa ;

sudo mkdir -p /tftpboot/pxelinux.cfg ;
sudo cp /usr/lib/syslinux/pxelinux.0 /tftpboot ;

echo 'DEFAULT ubuntu
LABEL ubuntu
kernel memdisk
append iso initrd=auto2.iso raw' | sudo tee /tftpboot/pxelinux.cfg/default ;

sudo cp /usr/lib/syslinux /tftpboot/ ;
sudo chmod -R 555 /tftpboot ;
sudo /etc/init.d/tftpd-hpa start ;


