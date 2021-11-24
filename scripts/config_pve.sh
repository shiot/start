#!/bin/bash
#
# Final Configurate the Proxmox HomeServer

#Load needed Files
source "${script_path}/sources/functions.sh"  # Functions needed in this Script
source "${script_path}/sources/variables.sh"  # Variables needed in this Script
source "${script_path}/language/${lang}.sh"   # Language Variables in this Script

# loads mainconfig file if exists
# loads mainconfig file if exists
if [ -f "${config_path}/${config_file}" ]; then
  source "${config_path}/${config_file}"
else
  echoLOG r "Es konnte keine Konfugurationsdatei gefunden werden"
  exit 1
fi

if [ -z "$1" ] && [[ "$1" == "update" ]]; then
  update=true
fi

whip_title="KONFIGURIERE HOMESERVER"

# enable S.M.A.R.T.-Support on root disk if available and disabled
if [ $(smartctl -a /dev/${pve_rootdisk} | grep -c "SMART support is: Available") -eq 1 ] && [ $(smartctl -a /dev/${pve_rootdisk} | grep -c "SMART support is: Disabled") -eq 1 ]; then
  smartctl -s on -a /dev/${pve_rootdisk}
fi

# if available, config second SSD as data Storage
if [ -n ${pve_datadisk} ]; then
  echoLOG b "Eine zweite SSD wurde im System gefunden und wird als Datenlaufwerk für Gastdatenträger/Images und ISO-Dateien an Proxmox gebunden"
  parted -s /dev/${pve_datadisk} "mklabel gpt" > /dev/null 2>&1
  parted -s -a opt /dev/${pve_datadisk} mkpart primary ext4 0% 100% > /dev/null 2>&1
  mkfs.ext4 -Fq -L ${pve_datadiskname} /dev/"${pve_datadisk}"1 > /dev/null 2>&1
  mkdir -p /mnt/${pve_datadiskname} > /dev/null 2>&1
  mount -o defaults /dev/"${pve_datadisk}"1 /mnt/${pve_datadiskname} > /dev/null 2>&1
  echo "UUID=$(lsblk -o LABEL,UUID | grep "${pve_datadiskname}" | awk '{print $2}') /mnt/${pve_datadiskname} ext4 defaults 0 2" >> /etc/fstab
  pvesm add dir ${pve_datadiskname} --path /mnt/${pve_datadiskname}
  pvesm set ${pve_datadiskname} --content iso,vztmpl,rootdir,images
  #Enable S.M.A.R.T.-Support, if available and disabled
  if [ $(smartctl -a /dev/${pve_datadiskname} | grep -c "SMART support is: Available") -eq 1 ] && [ $(smartctl -a /dev/${pve_datadiskname} | grep -c "SMART support is: Disabled") -eq 1 ]; then
    smartctl -s on -a /dev/${pve_datadiskname}
  fi
fi

# if available, create linux bridge on second Network adapter for SmartHome VLAN
if [ -n "${network_adapter1}" ]; then
  bak_file "backup" "/etc/network/interfaces"
  echo "auto vmbr1" >> /etc/network/interfaces
  echo "iface vmbr1 inet static" >> /etc/network/interfaces
  echo "        address $(echo ${vlan_iot_gw} | cut -d. -f1,2,3).$(echo ${pve_ip} | cut -d. -f4)/${vlan_iot_cidr}" >> /etc/network/interfaces
  echo "        gateway ${vlan_iot_gw}" >> /etc/network/interfaces
  echo "        bridge-ports ${network_adapter1}" >> /etc/network/interfaces
  echo "        bridge-stp off" >> /etc/network/interfaces
  echo "        bridge-fd 0" >> /etc/network/interfaces
  systemctl restart networking
  sleep 2
  echoLOG g "Zweite Netzwerkkarte wurde an IoT-Netzwerk gebunden"
fi

# if available, mount NAS as Backupstorage
if ${nas_exist}; then
  for N in $(seq 1 5); do
    pvesm add cifs backups --server "${nas_ip}" --share "backups" --username "${robot_name}" --password "${mail_password}" --content backup > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echoLOG g "Deine NAS wurde als Backuplaufwerk an Proxmox gebunden"
      pvesh create /pools --poolid BackupPool --comment "Von Maschinen in diesem Pool werden täglich Backups erstellt"
      echo "0 3 * * *   root   vzdump --compress zstd --mailto ${mail_rootadress} --mailnotification always --exclude-path /mnt/ --exclude-path /media/ --mode snapshot --quiet 1 --pool BackupPool --maxfiles 6 --storage backups" >> /etc/cron.d/vzdump
      echoLOG g "Backuppool und Backupjob für Container und virtuelle Maschienen erstellt"
      sleep 5
      #copy mainconfig to NAS
      echoLOG b "Die Konfigurationsdatei wird auf der NAS gesichert"
      cp "$shiot_configPath/$shiot_configFile" "/mnt/pve/backups/SHIoT_configuration.txt" > /dev/null 2>&1
      if [ $? -eq 0 ]; then echoLOG g "Kopiervorgang erfolgreich"; else echoLOG r "Kopiervorgang nicht erfolgreich"; fi
      break
    else
      whip_alert "Deine NAS konnte nicht als Backuplaufwerk eingerichtet werden, prüfe ob deine NAS eingeschaltet und erreichbar ist."
    fi
    if [ $N -eq 5 ]; then
      whip_alert "Es konnte keine Verbindung zu deiner NAS hergestellt werden, der Vorgang wird beendet"
    fi
  done
fi

# if set, config email notification in Proxmox
if [ -n "${mail_rootadress}" ]; then
  #Backup Files
  bak_file "backup" "/etc/aliases"
  bak_file "backup" "/etc/postfix/canonical"
  bak_file "backup" "/etc/postfix/sasl_passwd"
  bak_file "backup" "/etc/postfix/main.cf"
  bak_file "backup" "/etc/ssl/certs/ca-certificates.crt"

  #Start Configure
  if grep "root:" /etc/aliases; then
    sed -i "s/^root:.*$/root: ${mail_rootadress}/" /etc/aliases
  else
    echo "root: ${mail_rootadress}" >> /etc/aliases
  fi
  echo "root ${mail_senderaddress}" >> /etc/postfix/canonical
  chmod 600 /etc/postfix/canonical
  if [ -n "${mail_password}" ]; then
    mail_password=$(whiptail --passwordbox --ok-button " OK " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ERSTELLE KONFIGURATIONSDATEI " "\nWie lautet das Passwort, welches für den Login am Mailserver verwendet wird?" 10 80 3>&1 1>&2 2>&3)
  fi
  echo [${mail_server}]:${mail_port} "${mail_user}":"${mail_password}" >> /etc/postfix/sasl_passwd
  chmod 600 /etc/postfix/sasl_passwd 
  sed -i "/#/!s/\(relayhost[[:space:]]*=[[:space:]]*\)\(.*\)/\1"[${mail_server}]:"${mail_port}""/"  /etc/postfix/main.cf
  postconf smtp_use_tls=${var_mailtls}
  if ! grep "smtp_sasl_password_maps" /etc/postfix/main.cf; then
    postconf smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd > /dev/null 2>&1
  fi
  if ! grep "smtp_tls_CAfile" /etc/postfix/main.cf; then
    postconf smtp_tls_CAfile=/etc/ssl/certs/ca-certificates.crt > /dev/null 2>&1
  fi
  if ! grep "smtp_sasl_security_options" /etc/postfix/main.cf; then
    postconf smtp_sasl_security_options=noanonymous > /dev/null 2>&1
  fi
  if ! grep "smtp_sasl_auth_enable" /etc/postfix/main.cf; then
    postconf smtp_sasl_auth_enable=yes > /dev/null 2>&1
  fi 
  if ! grep "sender_canonical_maps" /etc/postfix/main.cf; then
    postconf sender_canonical_maps=hash:/etc/postfix/canonical > /dev/null 2>&1
  fi 
  postmap /etc/postfix/sasl_passwd > /dev/null 2>&1
  postmap /etc/postfix/canonical > /dev/null 2>&1
  systemctl restart postfix  &> /dev/null && systemctl enable postfix  &> /dev/null
  rm -rf "/etc/postfix/sasl_passwd"

  #Test Settings
  echo -e "Dies ist eine Testnachricht, versendet durch das Konfigurationsskript von https://SmartHome-IoT.net\n\nBestätige den Empfang der E-Mail mit \"Ja\" im Skript um Skript." | mail -a "From: \"HomeServer\" <${mail_senderaddress}>" -s "[SHIoT] Testnachricht" "${mail_rootadress}"
  if whip_yesno "JA" "NEIN" "$whip_title" "Es wurde eine E-Mail an folgende Adresse gesendet\n\n${mail_rootadress}\n\nWurde die E-Mail erfolgreich zugestellt? (Je nach Anbieter kann dies bis zu 15 Minuten dauern)"; then
    echoLOG g "Benachrichtigungen erfolgreich konfiguriert"
    if ! ${nas_exist}; then
      cp "$shiot_configPath/$shiot_configFile" "/tmp/SHIoT_configuration.txt"
      sed -i 's|robot_pw=".*"|robot_pw=""|g' "/tmp/SHIoT_configuration.txt"
      sed -i 's|mail_password=".*"|mail_password=""|g' "/tmp/SHIoT_configuration.txt"
      echo -e "Im Anhang findest Du die Datei \"SHIoT_configuration.txt\". Diese solltest du Sichern, um das Konfigurationsskript beim nächsten Mal im Wiederherstellungsmodus starten zu können.\n\n!!! ACHTUNG !!!\nAus sicherheitsgründen wurden sämtliche Passwörter vor dem Versand entfernt." | mail.mailutils -a "From: \"HomeServer\" <${mail_senderaddress}>" -s "[SHIoT] Konfigurationsskript" "${mail_rootadress}" -A "/tmp/SHIoT_configuration.txt"
    fi
  else
    whip_alert "Die Protokolldatei wird nun auf bekannte Fehler überprüft, gefundene Fehler werden automatisch behoben"
    if grep "SMTPUTF8 is required" "/var/log/mail.log"; then
      if ! grep "smtputf8_enable = no" /etc/postfix/main.cf; then
        postconf smtputf8_enable=no
        postfix reload
      fi
    fi
    echo -e "Dies ist eine Testnachricht, versendet durch das Konfigurationsskript von https://SmartHome-IoT.net\n\nBestätige den Empfang der E-Mail mit \"Ja\" im Skript um Skript." | mail -a "From: \"HomeServer\" <${mail_senderaddress}>" -s "[SHIoT] Testnachricht" "${mail_rootadress}"
    if whip_yesno "JA" "NEIN" "$whip_title" "Es wurde eine E-Mail an folgende Adresse gesendet\n\n${mail_rootadress}\n\nWurde die E-Mail erfolgreich zugestellt? (Je nach Anbieter kann dies bis zu 15 Minuten dauern)"; then
      echoLOG g "Benachrichtigungen erfolgreich konfiguriert"
      if ! ${nas_exist}; then
        cp "$shiot_configPath/$shiot_configFile" "/tmp/SHIoT_configuration.txt"
        sed -i 's|robot_pw=".*"|robot_pw=""|g' "/tmp/SHIoT_configuration.txt"
        sed -i 's|mail_password=".*"|mail_password=""|g' "/tmp/SHIoT_configuration.txt"
        echo -e "Im Anhang findest Du die Datei \"SHIoT_configuration.txt\". Diese solltest du Sichern, um das Konfigurationsskript beim nächsten Mal im Wiederherstellungsmodus starten zu können.\n\n!!! ACHTUNG !!!\nAus sicherheitsgründen wurden sämtliche Passwörter vor dem Versand entfernt." | mail.mailutils -a "From: \"HomeServer\" <${mail_senderaddress}>" -s "[SHIoT] Konfigurationsskript" "${mail_rootadress}" -A "/tmp/SHIoT_configuration.txt"
      fi
    else
      whip_alert "Du findest das Fehlerprotokoll in der folgenden Datei\n\n/var/log/mail.log\n\nDu kannst diese auf Fehler prüfen und die Konfiguration manuell durchführen"
      echoLOG b "E-Mail-Konfiguration wird rückgängig gemacht"
      #Recover Files
      bak_file "recover" "/etc/aliases"
      bak_file "recover" "/etc/postfix/canonical"
      bak_file "recover" "/etc/postfix/sasl_passwd"
      bak_file "recover" "/etc/postfix/main.cf"
      bak_file "recover" "/etc/ssl/certs/ca-certificates.crt"
    fi
  fi
fi

# Configure Proxmox Firewall
echoLOG b "Aktiviere und konfiguriere die Proxmox Firewall"
if [ ! -d "/etc/pve/firewall" ]; then mkdir -p "/etc/pve/firewall"; fi
if [ ! -d "/etc/pve/nodes/${pve_hostname}" ]; then mkdir -p "/etc/pve/nodes/${pve_hostname}"; fi
#Backup Files
bak_file "backup" "/etc/pve/firewall/cluster.fw"

#Cluster level firewall - IP SET
echo -e "[OPTIONS]\nenable: 1\n" >> $fw_cluster_file
##All private Networks
echo -e "[IPSET private] \0043 Alle privaten Netzwerke, wichtig für VPN\n10.0.0.0/8\n172.16.0.0/12\n192.168.0.0/16\n" >> $fw_cluster_file
if $vlan_available; then
  if [ -z "${vlan_unifi_gw}" ]; then
    echo -e "[IPSET unifi] \0043 Ubiquiti/UniFi Netzwerk\n${vlan_unifi_net}.0/${vlan_unifi_cidr} \0043 UniFi Netzwerk\n" >> $fw_cluster_file
  fi
  echo -e "[IPSET productive] \0043 Produktiv-Netzwerk (VLAN-ID ${vlan_productive_id})\n${vlan_productive_net}.0/${vlan_productive_cidr} \0043 VLAN-ID ${vlan_productive_id}\n" >> $fw_cluster_file
  echo -e "[IPSET iot] \0043 IoT-Netzwerk (VLAN-ID ${vlan_iot_id})\n${vlan_iot_net}.0/${vlan_iot_cidr} \0043 VLAN-ID ${vlan_iot_id}\n" >> $fw_cluster_file
  echo -e "[IPSET guest] \0043 Gäste-Netzwerk (VLAN-ID ${vlan_guest_id})\n${vlan_guest_net}.0/${vlan_guest_cidr} \0043 VLAN-ID ${vlan_guest_id}\n" >> $fw_cluster_file
  if $vlan_other; then
    vlan_is_count=$(cat "${config_path}/${config_file}" | grep 'vlan_.*id_' | cut -d_ -f4 | cut -d= -f1 | tail -n1)
    for N in $(seq 1 ${vlan_is_count}); do
      name="$(cat "${config_path}/${config_file}" | grep "vlan_.*id_${N}" | cut -d_ -f2 | cut -d= -f1)"
      echo -e "[IPSET ${name}] \0043 ${name}-Netzwerk (VLAN-ID $(cat "${config_path}/${config_file}" | grep "vlan_.*id_${N}" | cut -d= -f2)\n$(cat "${config_path}/${config_file}" | grep "vlan_.*net_${N}" | cut -d= -f2 | cut -d. -f1,2,3)/$(cat "${config_path}/${config_file}" | grep "vlan_.*cidr_${N}" | cut -d= -f2) \0043 VLAN-ID $(cat "${config_path}/${config_file}" | grep "vlan_.*id_${N}" | cut -d= -f2)\n" >> $fw_cluster_file
    done
  fi
  ###Create loggical IP-Sets
  if [ -z "${vlan_unifi_gw}" ]; then
    echo -e "[IPSET unifi-productive] \0043 Ubiquiti/UniFi- und Produktiv-Netzwerk\n${vlan_unifi_net}.0/${vlan_unifi_cidr} \0043 UniFi Netzwerk\n${vlan_productive_net}.0/${vlan_productive_cidr} \0043 VLAN-ID ${vlan_productive_id}\n" >> $fw_cluster_file
    echo -e "[IPSET unifi-iot] \0043 Ubiquiti/UniFi- und IoT-Netzwerk\n${vlan_unifi_net}.0/${vlan_unifi_cidr} \0043 UniFi Netzwerk\n${vlan_iot_net}.0/${vlan_iot_cidr} \0043 VLAN-ID ${vlan_iot_id}\n" >> $fw_cluster_file
    echo -e "[IPSET unifi-productive-iot] \0043 Ubiquiti/UniFi-, Produktiv- und IoT-Netzwerk\n${vlan_unifi_net}.0/${vlan_unifi_cidr} \0043 UniFi Netzwerk\n${vlan_productive_net}.0/${vlan_productive_cidr} \0043 VLAN-ID ${vlan_productive_id}\n${vlan_iot_net}.0/${vlan_iot_cidr} \0043 VLAN-ID ${vlan_iot_id}\n" >> $fw_cluster_file
  fi 
  echo -e "[IPSET productive-iot] \0043 Produktiv- und IoT-Netzwerk (VLAN-IDs ${vlan_productive_id} und ${vlan_iot_id})\n${vlan_productive_net}.0/${vlan_productive_cidr} \0043 VLAN-ID ${vlan_productive_id}\n${vlan_iot_net}.0/${vlan_iot_cidr} \0043 VLAN-ID ${vlan_iot_id}\n" >> $fw_cluster_file
  echo -e "[IPSET productive-guest] \0043 Produktiv- und Gäste-Netzwerk (VLAN-IDs ${vlan_productive_id} und ${vlan_guest_id})\n${vlan_productive_net}.0/${vlan_productive_cidr} \0043 VLAN-ID ${vlan_productive_id}\n${vlan_guest_net}.0/${vlan_guest_cidr} \0043 VLAN-ID ${vlan_guest_id}\n" >> $fw_cluster_file
else
  echo -e "[IPSET productive] \0043 Netzwerk\n${network_ip}.0/${network_cidr} \0043 eigener Netzwerkbereich\n" >> $fw_cluster_file
fi
##Create Proxmox needs
echo -e "[RULES]\nGROUP fwsg_proxmox\n\n[group fwsg_proxmox]\nIN SSH(ACCEPT) -source +productive -log nolog\nIN ACCEPT -source +private -p tcp -dport 8006 -log nolog\nIN ACCEPT -source +private -p tcp -dport 5900:5999 -log nolog\nIN ACCEPT -source +private -p tcp -dport 3128 -log nolog\nIN ACCEPT -source +private -p udp -dport 111 -log nolog\nIN ACCEPT -source +private -p udp -dport 5404:5405 -log nolog\nIN ACCEPT -source +private -p tcp -dport 60000:60050 -log nolog\n\n" >> $fw_cluster_file
echo -e "[OPTIONS]\nenable: 1\n\n[RULES]\nGROUP fwsg_proxmox\n" > "/etc/pve/nodes/$pve_hostname/host.fw"

# Set email notification about hard disk errors, check every 12 hours
#Backup Files
bak_file "backup" "/etc/default/smartmontools"
bak_file "backup" "/etc/smartd.conf"

#Start Configure
sed -i 's|#s|s|' /etc/default/smartmontools
echo -e "\n# uncomment to start smartd on system startup\nstart_smartd=yes" >> /etc/default/smartmontools
sed -i 's|DEVICESCAN -d removable -n standby -m root -M exec /usr/share/smartmontools/smartd-runner|DEVICESCAN -m '"${mail_rootadress}"' -M exec /usr/share/smartmontools/smartd-runner|' /etc/default/smartmontools
sed -i 's|DEVICESCAN -d removable -n standby -m root -M exec /usr/share/smartmontools/smartd-runner|#DEVICESCAN -d removable -n standby -m root -M exec /usr/share/smartmontools/smartd-runner|' /etc/smartd.conf
if [ -n ${pve_datadisk} ]; then
  sed -i 's|#/dev/sdc -a -I 194 -W 4,45,55 -R 5 -m admin@example.com|/dev/'"${pve_rootdisk}"' -a -I 194 -W 4,45,55 -R 5 -m '"${mail_rootadress}"'\n/dev/'"${pve_datadisk}"' -a -I 194 -W 4,45,55 -R 5 -m '"${mail_rootadress}"'|' /etc/smartd.conf
else
  sed -i 's|#/dev/sdc -a -I 194 -W 4,45,55 -R 5 -m admin@example.com|/dev/'"${pve_rootdisk}"' -a -I 194 -W 4,45,55 -R 5 -m '"${mail_rootadress}"'|' /etc/smartd.conf
fi
systemctl restart smartmontools
