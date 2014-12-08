#!/bin/sh

#LiquidVPN DD-WRT Connection Creator 1.0
#Copyright (C) 2014 David Cox
#Email: dave@liquidvpn.com
#This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#Usage: From any Linux terminal session including your DD-WRT router upload
#Conn_Creator.sh and your VPN services ca.crt and optional ta.key then run it
#with user@DD-WRT~:sh Conn_Creator.sh then follow the prompts. It will generate
#a new script that you can then copy and paste into your DD-WRT routers Admin/Commands section
#in the WebUI. This script should work with any VPN service that uses a user/pass. 
#You may need to change the cipher AES-256-CBC if your VPN service uses BF-CBC or AES-128-CBC.
#Look in a .ovpn file or ask your provider for the cipher if you are unsure. 


#Read variables below,
#
#
#- Connection Name
#- User and Password
#- Remote servers ( space separated )
#- Protocol
#- port
#- CA cert
#- TLS-AUT key

debug=0;

while [ 1 ]
do

echo "Enter Connection Name:"
read conn;


# Connection name can be alphanum and space, underscore

echo $conn |grep -Ei "^[a-z0-9\ _]*$" >/dev/null;
if [ $? -eq 0 ]
then
   break;
fi
     echo "Connection name can include alphanum,space and underscore, Nothing else";

done



while [ 1 ]
do
echo "Enter User Name:"
read user;
echo $user|grep -E "^$" >/dev/null;
if [ $? -eq 0 ]
then
	echo "User name can't be empty";
	continue;
else
	break;
fi
done


while [ 1 ]
do
echo "Enter Password:"
read pass;
echo $pass|grep -E "^$" >/dev/null;
if [ $? -eq 0 ]
then
        echo "Password can't be empty";
        continue;
else
	break;
fi

done

count=1

while [ 1 ]
do
echo "Enter VPN server : IP:PORT"
read ip;

echo  $ip |grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\:[0-9]{1,5}$" >/dev/null;
if [ $? -eq 0 ]
then
	true;
else
	echo "IP:PORT doesn't match syntax, wrong ip";
	count=$count;
	continue;
fi


if [ $count -eq 1 ]
then
 ip1=$ip;
elif [ $count -eq 2 ]
then
 ip2=$ip;
elif [ $count -eq 3 ]
then
 ip3=$ip;
elif [ $count -eq 4 ]
then
 ip4=$ip;
 break;
fi

echo "Do you want to another redundant server IP:  (y/n)  "
read bool;
if [ "$bool" = y -a $count -lt 4 ]
then
	count=$(($count + 1 ));
	continue;
elif [ "$bool" = n -o $count -eq 4 ]
then
    break;
else
   break;
fi

done

while [ 1 ]
do

echo "Enter protocol (udp/tcp) : "
read proto;

if [ "$proto" = "udp" -o "$proto" = "tcp"  ]
then
   break;
else
	continue;
fi


done
while [ 1 ]
do
echo "Enter file location containing CA cert:"
read cacert;

if [ -f "$cacert" ]
then
	break;
else
	echo "Incorrect file location"
	continue;
fi

done

tlsauth=0;
echo "Do you want to use tls-auth (y/n)"
read bool

if [ "$bool" = 'y' ]
then
while [ 1 ]
do
echo "Enter file location containing TLS key:"
read tlskey;

if [ -f $tlskey ]
then
	tlsauth=1;
        break;
else
        echo "Incorrect file location"
        continue;
fi

done
else
 break;	

fi


if [ $debug -eq 1 ]
then
	echo $conn;
	echo $user;
	echo $pass;
	echo $ip1;
	echo $ip2;
	echo $ip3;
	echo $ip4;
	echo $proto;
	cat $cacert;
fi

#Generating script

echo "#!/bin/sh" > $conn.sh


echo 'OPVPNENABLE=`nvram get openvpncl_enable | awk '$1 == "0" {print $1}'`

if [ "$OPVPNENABLE" != 0 ]; then
   nvram set openvpncl_enable=0
   nvram commit
fi' >> $conn.sh

echo 'sleep 10' >> $conn.sh

echo 'mkdir /tmp/liquid; cd /tmp/liquid' >> $conn.sh

echo  "USERNAME='$user'
PASSWORD='$pass'
PROTO=$proto
REMOTE=$ip1 $ip2 $ip3 $ip4" >>$conn.sh

echo 'echo "#!/bin/sh
iptables -t nat -I POSTROUTING -o tun0 -j MASQUERADE" > route-up.sh' >> $conn.sh


echo 'echo "#!/bin/sh
iptables -t nat -D POSTROUTING -o tun0 -j MASQUERADE" > route-down.sh' >> $conn.sh


echo  "  echo \"\$USERNAME\" > userpass.conf  ">> $conn.sh
echo  "  echo \"\$PASSWORD\" >> userpass.conf  ">> $conn.sh


echo "sleep 10" >> $conn.sh


echo "echo \"client
proto $proto \" > liquid.conf " >> $conn.sh

for ip in $ip1 $ip2 $ip3 $ip4 
do


if [ -n "$ip" ]
then
	oip=$(echo $ip|cut -d: -f1)
	oport=$(echo $ip|cut -d: -f2)
	echo "echo \"remote $oip $oport\" >>liquid.conf" >> $conn.sh
fi

done
#Note the cipher. Change it as needed. 
echo  "echo \"remote-random
dev tun
resolv-retry 20
redirect-gateway def1
nobind
persist-key
persist-tun
cipher AES-256-CBC
auth SHA512
reneg-sec 0\" >> liquid.conf " >> $conn.sh



echo " echo \"auth-user-pass /tmp/liquid/userpass.conf \" >> liquid.conf " >> $conn.sh


if [ "$proto" = "udp"  ]
then
	echo "echo \"#explicit-exit-notify 5\" >> liquid.conf " >> $conn.sh
	
fi


echo "echo \"remote-cert-tls server
comp-lzo no
script-security 2\" >> liquid.conf " >> $conn.sh


if [ "$tlsauth" -eq 1 ]
then

echo "echo \"tls-auth [inline] 1\" >> liquid.conf " >> $conn.sh

fi

echo " CA_CRT='$(cat $cacert)'" >>$conn.sh
echo "echo \"<ca>\" >> liquid.conf " >> $conn.sh
echo "echo \"\$CA_CRT\" >> liquid.conf" >> $conn.sh
echo "echo \"</ca>\" >> liquid.conf " >> $conn.sh

if [ "$tlsauth" -eq 1 ]
then

echo " TLS_AUTH='$(cat $tlskey)'" >>$conn.sh
echo "echo \"<tls-auth>\" >> liquid.conf " >> $conn.sh
echo "echo \"\$TLS_AUTH\" >> liquid.conf ">> $conn.sh
echo "echo \"</tls-auth>\" >> liquid.conf " >> $conn.sh

fi



echo "chmod 644 ca.crt; chmod 600 userpass.conf; chmod 700 route-up.sh route-down.sh" >> $conn.sh
echo "ln -s /tmp/liquid/liquidvpn.log /tmp/liquidvpn.log" >> $conn.sh
echo "ln -s /tmp/liquid/status /tmp/status" >> $conn.sh
echo '(killall openvpn; openvpn --config /tmp/liquid/liquid.conf --route-up /tmp/liquid/route-up.sh --down /tmp/liquid/route-down.sh) &
exit 0' >> $conn.sh

chmod +x $conn.sh


