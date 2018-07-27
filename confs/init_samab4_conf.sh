#!/bin/bash

SAMBA_DOMAIN_LOWERCASE=`echo ${SAMBA_DOMAIN} | tr '[:upper:]' '[:lower:]'`
SAMBA_DOMAIN_UPPERCASE=`echo ${SAMBA_DOMAIN} | tr '[:lower:]' '[:upper:]'`
SAMBA_REALM_LOWERCASE=`echo ${SAMBA_REALM} | tr '[:upper:]' '[:lower:]'`
SAMBA_REALM_UPPERCASE=`echo ${SAMBA_REALM} | tr '[:lower:]' '[:upper:]'`

DATABASE_SAMBA_PATH="/usr/local/samba/private/sam.ldb"

echo "----------SET DOMAI:dc.${DOMAIN} COMFIGURATION IN /etc/hosts FILE---------------"
rm /etc/krb5.conf 
echo "172.20.0.1 dc.${DOMAIN} dc" >> /etc/hosts

if [ ! -f $DATABASE_SAMBA_PATH ]; then

    echo "--------------------SAMBA COMFIGURATION-----------------------------------------"
    /usr/local/samba/bin/samba-tool domain provision --use-rfc2307 --domain=${SAMBA_DOMAIN_UPPERCASE} --realm=${SAMBA_REALM_UPPERCASE} --server-role=dc --dns-backend=SAMBA_INTERNAL --adminpass=${SAMBA_ADMIN_PASSWORD}
    ln -sf /usr/local/samba/private/krb5.conf /etc/krb5.conf   
    rm -rf /lib64/libnss_winbind.so.2
    ln -s /usr/local/samba/lib/libnss_winbind.so.2 /lib64/
    ln -s /lib64/libnss_winbind.so.2 /lib64/libnss_winbind.so
    ldconfig
    cp /tmp/smb.conf /usr/local/samba/etc/smb.conf
    cp /tmp/krb5.conf /etc/krb5.conf

    if [[ ! -z $SAMBA_DOMAIN ]]; then
        echo "----------SET DOMAIN IN SAMBA COMFIGURATION------------------------------"
        sed -i "s/MYCOMPANY/${SAMBA_DOMAIN_UPPERCASE}/" /usr/local/samba/etc/smb.conf
        sed -i "s/MYCOMPANY.LOCAL/${SAMBA_REALM_UPPERCASE}/" /usr/local/samba/etc/smb.conf
        sed -i "s/mycompany.local/${SAMBA_REALM_LOWERCASE}/" /usr/local/samba/etc/smb.conf

        echo "----------SET DOMAIN IN KERBEROS SAMBA COMFIGURATION----------------------"

        sed -i "s/MYCOMPANY.LOCAL/${SAMBA_REALM_UPPERCASE}/" /etc/krb5.conf
        sed -i "s/mycompany.local/${SAMBA_REALM_LOWERCASE}/" /etc/krb5.conf
    fi


    samba-tool domain passwordsettings set --complexity=off  && /usr/local/samba/sbin/samba -D
else
    echo "########################################################"
    echo "THIS CONTAINER WILL NOT REQUIRE A NEW SAMBA INSTALATION#"
    echo "SAMBA INSTALATION WAS FOUND                            #"
    echo "########################################################"
fi

echo "########################################################"
echo "COMMAND TO SET PORTS IN FIREWALL IN SYSTEMD            #"
echo ' for port in 53/tcp 53/udp 88/tcp 88/udp 135/tcp 137/udp 138/udp 139/tcp 389/tcp 389/udp 445/tcp 464/tcp 464/udp 636/tcp;
                do 
                firewall-cmd --permanent --add-port=$port;
                done && firewall-cmd --reload '
echo "########################################################"