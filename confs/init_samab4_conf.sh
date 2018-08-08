#!/bin/bash

SAMBA_DOMAIN_LOWERCASE=`echo ${SAMBA_DOMAIN} | tr '[:upper:]' '[:lower:]'`
SAMBA_DOMAIN_UPPERCASE=`echo ${SAMBA_DOMAIN} | tr '[:lower:]' '[:upper:]'`
SAMBA_REALM_LOWERCASE=`echo ${SAMBA_REALM} | tr '[:upper:]' '[:lower:]'`
SAMBA_REALM_UPPERCASE=`echo ${SAMBA_REALM} | tr '[:lower:]' '[:upper:]'`

DATABASE_SAMBA_FILE="/usr/local/samba/private/sam.ldb"
SMB_CONF_FILE="/usr/local/samba/etc/smb.conf"
KRB5_FILE="/etc/krb5.conf"

#! -f $DATABASE_SAMBA_FILE -a

if [ ! -f $SMB_CONF_FILE ] 
then
    rm /etc/krb5.conf 
    echo "--------------------SAMBA CONFIG-----------------------------------------"
    /usr/local/samba/bin/samba-tool domain provision --use-rfc2307 \
                                                    --domain=${SAMBA_DOMAIN_UPPERCASE} \
                                                    --realm=${SAMBA_REALM_UPPERCASE} \
                                                    --server-role=dc \
                                                    --dns-backend=SAMBA_INTERNAL \
                                                    --adminpass=${SAMBA_ADMIN_PASSWORD} \
                                                    --ldapadminpass=${SAMBA_ADMIN_PASSWORD} \
                                                    --host-name=${NETBIOS_NAME} \
                                                    --host-ip=${IP_BIND_SAMBA_AD_SERVER}

    sleep 2
    echo "--------------------SETUP LIBS-----------------------------------------"
    rm -rf /lib64/libnss_winbind.so.2
    ln -s /usr/local/samba/lib/libnss_winbind.so.2 /lib64/
    ln -s /lib64/libnss_winbind.so.2 /lib64/libnss_winbind.so
    ldconfig
else
    echo "########################################################"
    echo "THIS CONTAINER WILL NOT REQUIRE A NEW SAMBA INSTALATION#"
    echo "SAMBA INSTALATION WAS FOUND                            #"
    echo "VERIFY FILES :                                         #"
    echo "smb.conf: /usr/local/samba/etc/                        #"
    echo "all-data-samba-files: /usr/local/samba/private/        #"
    echo "krb5.conf: /etc/krb5.conf                              #"
    echo "########################################################"
fi

sleep 2
echo "--------------------KRB5 CONFIG-----------------------------------------"
rm /usr/local/samba/private/krb5.conf
cp /tmp/krb5.conf /usr/local/samba/private/
ln -sf /usr/local/samba/private/krb5.conf /etc/krb5.conf 
cat /etc/krb5.conf

sleep 2
echo "-------------START DEAMON SAMBA: /usr/local/samba/sbin/samba ----------"
/usr/local/samba/sbin/samba -D

sleep 6
echo -e "SET /etc/resolv.conf:\necho -e "search ${DOMAIN}\nnamespace ${IP_BIND_SAMBA_AD_SERVER}" > /etc/resolv.conf"
echo -e "search ${DOMAIN}\nnamespace ${IP_BIND_SAMBA_AD_SERVER}" > /etc/resolv.conf

sleep 2
echo "SET KERBEROS PASSWORD Administrator@${SAMBA_REALM_UPPERCASE}:
     echo ${SAMBA_ADMIN_PASSWORD} | kinit Administrator@${SAMBA_REALM_UPPERCASE} ----------"
echo ${SAMBA_ADMIN_PASSWORD} | kinit Administrator@${SAMBA_REALM_UPPERCASE}

samba-tool domain passwordsettings set --complexity=off

echo "To enable hosts to receive user and group information 
        from a domain using Winbind, you must create two symbolic 
        links in a directory of the operating system's library path.
        https://wiki.samba.org/index.php/Libnss_winbind_Links"

ln -s /usr/local/samba/lib/libnss_winbind.so.2 /lib64/
ln -s /lib64/libnss_winbind.so.2 /lib64/libnss_winbind.so
ldconfig

echo "Configuring the Name Service Switch"
sed -i "s/passwd:     files sss/passwd:     files sss winbind/" /etc/nsswitch.conf
sed -i "s/group:      files sss/group:      files sss winbind/" /etc/nsswitch.conf

echo -e"########################################################\n
#               COMMAND TO SET PORTS IN FIREWALL IN SYSTEMD     #\n
for port in 53/tcp 
            53/udp 
            88/tcp 
            88/udp 
            135/tcp 
            137/udp 
            138/udp 
            139/tcp 
            389/tcp 
            389/udp 
            445/tcp 
            464/tcp 
            464/udp 
            636/tcp;
do firewall-cmd --permanent --add-port=$port;
done && firewall-cmd --reload \n
##########################################################################"
