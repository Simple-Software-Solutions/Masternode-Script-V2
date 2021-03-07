#!/bin/bash
sudo echo " "

if (whiptail --title "SSS Masternode" --yesno "Is it okay to add user(s) sss*" 8 78); then
    echo ""
else
    echo "User selected No. Bye!"
	exit 0
fi

CURRENT=$(whiptail --inputbox "How many SSS MN have you running at the moment?" 8 39 0 --title "SSS Masternode" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
	echo ""
else
    echo "User selected Cancel. Bye!"
	exit 0
fi
echo "Installing system updates"
	{
	sudo apt update -y
	sudo apt upgrade -y
	} &> ~/sss_install.log;
	
echo "Setting up Firewall"
	{
	sudo ufw allow 22
	sudo ufw --force enable
	} &> ~/sss_install.log;
	
echo "Downloading SSS"
{
wget -P /tmp https://github.com/Simple-Software-Solutions/SSS-Core/releases/download/sssolutions_v2.1.1/sss-2.1.1-x86_64-linux-gnu.tar.gz
} &> ~/sss_install.log;

IP4=$(curl -s4 ifconfig.co)
if [ $CURRENT = 1 ]; then
	n=1
	while (( $n <= 3 ))
	do
	IPMN1=$(whiptail --inputbox "Put in the IP from your first MN (v4/v6)." 8 39 $IP4 --title "SSS Masternode" 3>&1 1>&2 2>&3)                                                                       
	exitstatus=$?
		if [ $exitstatus = 0 ]; then
			n=3
			sudo echo "bind=$IP" >>	/home/sss1/sss-2.1.1/config/sss.conf
			break
		else
			if [ $n = 3 ]; then
				echo "Try again, by running script"
				exit 1
			else	
				n=$(( n+1 ))
			fi
		fi
	done
fi

(( CURRENT++ ))

mn=1
while (( $mn <= 10 ))
do
	U=sss$CURRENT
	RPC=$((51470 + $CURRENT))
	{
	sudo adduser --gecos GECOS $U --disabled-password
	sudo adduser $U sudo
	sudo su $U -c "
	tar -xvf /tmp/sss-2.1.1-x86_64-linux-gnu.tar.gz -C /home/$U 
	mkdir /home/$U/sss-2.1.1/config"
	} &> ~/sss_install.log;
	 

	
	n=1
	while (( $n <= 3 ))
	do
	IP=$(whiptail --inputbox "Put in your MN IP(v4/v6)." 8 39 $IP4 --title "SSS Masternode" 3>&1 1>&2 2>&3)                                                                       
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
	n=3
	break
	else
		if [ $n = 3 ]; then
			echo "Try again, by running script"
			exit 1
		else	
			n=$(( n+1 ))
		fi
	fi
	done

	n=1
	while (( $n <= 3 ))
	do
	PRIVKEY=$(whiptail --inputbox "Copy MN PrivKey from wallet." 8 39 --title "SSS Masternode" 3>&1 1>&2 2>&3)                                                                       
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		n=3
		break
	else
		if [ $n = 3 ]; then
			echo "Try again, by running script"
			exit 1
		else	
			n=$(( n+1 ))
		fi
	fi
	done
	
	echo "Installing Masternode $mn"
	
	sudo echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >		/home/$U/sss-2.1.1/config/sss.conf
	sudo echo "rpcpassword=passw"`shuf -i 100000-10000000 -n 1` >>	/home/$U/sss-2.1.1/config/sss.conf
	sudo echo "rpcallowip=127.0.0.1" >>								/home/$U/sss-2.1.1/config/sss.conf
	sudo echo "server=1" >>											/home/$U/sss-2.1.1/config/sss.conf
	sudo echo "daemon=1" >>											/home/$U/sss-2.1.1/config/sss.conf
	sudo echo "logtimestamps=1" >>									/home/$U/sss-2.1.1/config/sss.conf
	sudo echo "maxconnections=256" >>								/home/$U/sss-2.1.1/config/sss.conf
	sudo echo "masternode=1" >>										/home/$U/sss-2.1.1/config/sss.conf
	sudo echo "externalip=$IP" >>									/home/$U/sss-2.1.1/config/sss.conf
	sudo echo "masternodeprivkey=$PRIVKEY" >>						/home/$U/sss-2.1.1/config/sss.conf
	sudo echo "rpcport=$RPC" >>		 								/home/$U/sss-2.1.1/config/sss.conf
	

	if [ $CURRENT > 1 ]; then
		sudo echo "bind=$IP" >>										/home/$U/sss-2.1.1/config/sss.conf
	fi

	sudo echo "[Unit]" > 								/etc/systemd/system/$U.service
	sudo echo "Description=$U service" >>		/etc/systemd/system/$U.service
	sudo echo "After=network.target" >>					/etc/systemd/system/$U.service
	sudo echo "[Service]" >>							/etc/systemd/system/$U.service
	sudo echo "User=$U" >>						/etc/systemd/system/$U.service
	sudo echo "Group=$U" >>						/etc/systemd/system/$U.service
	sudo echo "Type=forking" >>							/etc/systemd/system/$U.service
	sudo echo "ExecStart=/home/$U/sss-2.1.1/bin/sssolutionsd -daemon -forcestart -conf=/home/$U/sss-2.1.1/config/sss.conf -datadir=/home/$U/sss-2.1.1/config" >> /etc/systemd/system/$U.service
	sudo echo "ExecStop=/home/$U/sss-2.1.1/bin/sssolutions-cli stop -conf=/home/$U/sss-2.1.1/config/sss.conf -datadir=/home/$U/sss-2.1.1/config" >> /etc/systemd/system/$U.service
	sudo echo "Restart=always" >>						/etc/systemd/system/$U.service
	sudo echo "PrivateTmp=true" >>						/etc/systemd/system/$U.service
	sudo echo "TimeoutStopSec=60s" >>					/etc/systemd/system/$U.service
	sudo echo "TimeoutStartSec=10s" >>					/etc/systemd/system/$U.service
	sudo echo "StartLimitInterval=120s" >>				/etc/systemd/system/$U.service	
	sudo echo "StartLimitBurst=5" >>					/etc/systemd/system/$U.service
	sudo echo "[Install]" >>							/etc/systemd/system/$U.service
	sudo echo "WantedBy=multi-user.target" >>			/etc/systemd/system/$U.service

	echo "#!/bin/bash" > /home/$U/sss-2.1.1/bin/sssolutions-cli$CURRENT
	echo "if [ \$# == 0 ]; then" >> /home/$U/sss-2.1.1/bin/sssolutions-cli$CURRENT
	echo "echo \"need more parameters (eg. help)\"" >> /home/$U/sss-2.1.1/bin/sssolutions-cli$CURRENT
	echo "elif [ \$# == 1 ]; then" >> /home/$U/sss-2.1.1/bin/sssolutions-cli$CURRENT
	echo "/home/$U/sss-2.1.1/bin/sssolutions-cli -conf=/home/$U/sss-2.1.1/config/sss.conf -datadir=/home/$U/sss-2.1.1/config \$1" >> /home/$U/sss-2.1.1/bin/sssolutions-cli$CURRENT
	echo "elif [ \$# == 2 ]; then" >> /home/$U/sss-2.1.1/bin/sssolutions-cli$CURRENT
	echo "/home/$U/sss-2.1.1/bin/sssolutions-cli -conf=/home/$U/sss-2.1.1/config/sss.conf -datadir=/home/$U/sss-2.1.1/config \$1 \$2" >> /home/$U/sss-2.1.1/bin/sssolutions-cli$CURRENT
	echo "fi" >> /home/$U/sss-2.1.1/bin/sssolutions-cli$CURRENT
	echo "exit 0" >> /home/$U/sss-2.1.1/bin/sssolutions-cli$CURRENT
	chmod +x /home/$U/sss-2.1.1/bin/sssolutions-cli$CURRENT
	sudo ln -s /home/$U/sss-2.1.1/bin/sssolutions-cli$CURRENT /usr/bin/
	
	{
	sudo service $U start
	sudo systemctl enable $U 
	} &>> ~/sss_install.log
	
	sudo systemctl is-active --quiet $U
	if [ $? -ne 0 ]; then
		echo "Installation failed!"
		exit 0
	fi
	
	if (whiptail --title "Multiple Masternodes" --yesno "Do you want to setup another masternode?" 8 78); then
		(( mn++ ))
		CURRENT=$(( CURRENT+1 ))
		if [ $CURRENT = 2 ]; then
			sudo echo "bind=$IP" >>							/home/$U/sss-2.1.1/config/sss.conf
		fi
	else
		echo "Installation done!"	
		echo " "
		echo "Succesfully setup $mn Masternode(s)"
		echo " "
		echo "Use eg \"sssolutions-cli$CURRENT help\" to see all commands"
		echo " "
		exit 0
	fi
	done
sudo rm /tmp/sss-2.1.1-x86_64-linux-gnu.tar.gz
sudo rm ~/sss_install.log
exit 0
