#!/bin/bash
#
# Create the Mainconfiguration file, if the file exists, for example because a version
# update has to be executed, the file will be recreated

#Load needed Files
source "${script_path}/sources/functions.sh"  # Functions needed in this Script
source "${script_path}/sources/variables.sh"  # Variables needed in this Script
source "${script_path}/language/${main_language}.sh"   # Language Variables in this Script

whip_title="ERSTELLE/AKTUALISIERE KONFIGURATIONSDATEI"

# loads mainconfig file if exists
if [ -f "${config_path}/${config_file}" ]; then source "${config_path}/${config_file}"; fi

# checks loaded config Version
if [[ ${version_mainconfig} != "${config_version}" ]]; then update=true; else update=false; fi

function vlan() {
# Set Networkconfiguration
  if whip_yesno "JA" "NEIN" "${whip_title}" "Nutzt Du VLANs in deinem Netzwerk?"; then
    vlan_available=true
    if whip_yesno "JA" "NEIN" "${whip_title}" "Nutzt Du ein Ubiquiti Gateway (DreamMachine/DreamMachine Pro/ Security Gateway)?"; then
      if $update; then
        vlan_unifi_gw=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die Gateway-IP deines Unifinetzwerk?" "${vlan_unifi_net}")
      else
        vlan_unifi_gw=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die Gateway-IP deines Unifinetzwerk?" "192.168.0")
      fi
    fi
    if $update; then
      vlan_productive_id=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die VLAN-ID deines Produktivnetzwerk (z.B. Server)?" "${vlan_productive_id}")
    else
      vlan_productive_id=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die VLAN-ID deines Produktivnetzwerk (z.B. Server)?")
    fi
    if $update; then
      vlan_productive_gw=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die Gateway-IP deines Produktivnetzwerk?" "${vlan_productive_gw}")
    else
      vlan_productive_gw=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die Gateway-IP deines Produktivnetzwerk?" "$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1 | cut -d. -f1,2,3)")
    fi
    if $update; then
      vlan_productive_cidr=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die CIDR deines Produktivnetzwerk?" "${vlan_productive_cidr}")
    else
      vlan_productive_cidr=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die CIDR deines Produktivnetzwerk?" "24")
    fi
    if $update; then
      vlan_iot_id=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die VLAN-ID deines IoT-Netzwerk (SmartHome Geräte)?" "${vlan_iot_id}")
    else
      vlan_iot_id=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die VLAN-ID deines IoT-Netzwerk (SmartHome Geräte)?" "20")
    fi
    if $update; then
      vlan_iot_gw=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die Gateway-IP deines IoT-Netzwerk?" "${vlan_iot_gw}")
    else
      vlan_iot_gw=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die Gateway-IP deines IoT-Netzwerk?")
    fi
    if $update; then
      vlan_iot_cidr=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die CIDR deines IoT-Netzwerk?" "${vlan_iot_cidr}")
    else
      vlan_iot_cidr=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die CIDR deines IoT-Netzwerk?" "24")
    fi
    if $update; then
      vlan_guest_id=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die VLAN-ID deines Gastnetzwerk?" "${vlan_guest_id}")
    else
      vlan_guest_id=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die VLAN-ID deines Gastnetzwerk?" "30")
    fi
    if $update; then
      vlan_guest_gw=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die Gateway-IP deines Gastnetzwerk?" "${vlan_guest_gw}")
    else
      vlan_guest_gw=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die Gateway-IP deines Gastnetzwerk?")
    fi
    if $update; then
      vlan_guest_cidr=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die CIDR deines Gastnetzwerk?" "${vlan_guest_cidr}")
    else
      vlan_guest_cidr=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die CIDR deines Gastnetzwerk?" "24")
    fi
    if [ -f "${tmp_vlan}" ]; then rm "${tmp_vlan}"; fi
    touch "${tmp_vlan}"
    if $update; then
      vlan_is_count=$(cat "${config_path}/${config_file}" | grep 'vlan_.*id_' | cut -d_ -f4 | cut -d= -f1 | tail -n1)
      vlan_count=$(whip_inputbox "OK" "${whip_title}" "Wieviele weitere VLANs möchtest du einrichten?" "${vlan_is_count}")
      for N in $(seq 1 ${vlan_count}); do
        name=$(whip_inputbox "OK" "${whip_title}" "Wie nennst Du dieses VLAN?" "$(cat "${config_path}/${config_file}" | grep "vlan_.*id_${N}" | cut -d_ -f2 | cut -d= -f1)")
        id=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die VLAN-ID von $name?" "$(cat "${config_path}/${config_file}" | grep "vlan_.*id_${N}" | cut -d= -f2)")
        gw=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die Gateway-IP von $name?" "$(cat "${config_path}/${config_file}" | grep "vlan_.*net_${N}" | cut -d= -f2)")
        cidr=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die CIDR von $name?" "$(cat "${config_path}/${config_file}" | grep "vlan_.*cidr_${N}" | cut -d= -f2)")
        echo -e "vlan_${name}_id_${N}=${id}" >> "${tmp_vlan}"
        echo -e "vlan_${name}_net_${N}=\"$(echo ${gw} | cut -d. -f1,2,3)\"" >> "${tmp_vlan}"
        echo -e "vlan_${name}_gw_${N}=\"${gw}\"" >> "${tmp_vlan}"
        echo -e "vlan_${name}_cidr_${N}=\"${cidr}\"" >> "${tmp_vlan}"
      done
    else
      if whip_yesno "JA" "NEIN" "${whip_title}" "Möchtest Du weitere VLANs einrichten?"; then
        vlan_count=$(whip_inputbox "OK" "${whip_title}" "Wieviele weitere VLANs möchtest du einrichten?")
        echo -e "vlan_count=${vlan_count}"
        for N in $(seq 1 ${vlan_count}); do
          name=$(whip_inputbox "OK" "${whip_title}" "Wie nennst Du dieses VLAN?")
          id=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die VLAN-ID von $name?")
          gw=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die Gateway-IP von $name?")
          cidr=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die CIDR von $name?")
          echo -e "vlan_${name}_id_${N}=${id}" >> "${tmp_vlan}"
          echo -e "vlan_${name}_net_${N}=\"$(echo ${gw} | cut -d. -f1,2,3)\"" >> "${tmp_vlan}"
          echo -e "vlan_${name}_gw_${N}=\"${gw}\"" >> "${tmp_vlan}"
          echo -e "vlan_${name}_cidr_${N}=\"${cidr}\"" >> "${tmp_vlan}"
        done
      fi
    fi
  else
    vlan_available=false
  fi
}

function netrobot() {
# config Netrobot
  if $update; then
    robot_name=$(whip_inputbox "OK" "${whip_title}" "Wie lautet der Benutzername, den Du deinem Netzwerkroboter zugewiesen hast?" "$(echo ${robot_name})")
    robot_pw=$(whip_inputbox_password "OK" "${whip_title}" "Wie lautet das Passwort, welches Du deinem Netzwerkroboter zugewiesen hast?" "$(echo ${robot_pw})")
  else
    robot_name=$(whip_inputbox "OK" "${whip_title}" "Wie lautet der Benutzername, den Du deinem Netzwerkroboter zugewiesen hast?" "netrobot")
    robot_pw=$(whip_inputbox_password "OK" "${whip_title}" "Wie lautet das Passwort, welches Du deinem Netzwerkroboter zugewiesen hast?\nWenn Du hier kein Passwort eingibst, wird automatisch ein sicheres 26-Zeichen langes Passwort erstellt.")
    if [[ $robot_pw == "" ]]; then
      robot_pw=$(generatePassword 26)
      whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net" --title " ${whip_title} " "\nErstelle einen Benutzer auf deinen Geräten mit folgenden Daten und weise diesem Benutzer Administratorrechte zu. Wichtig ist, das dieser Benutzer auf deiner NAS angelegt wird!\n\nBenutzername: ${robot_name}\nPasswort: ${robot_pw}" 10 80
    fi
  fi
}

function nas() {
# Set NAS configuration
  if $nas_exist; then
    if $update; then
      nas_ip=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die IP-Adresse deiner NAS?" "${nas_ip}")
      if check_ip "${nas_ip}"; then
        nas_exist=true
        nas_ip=${ip}
      else
        nas_exist=false
        nas_ip=
      fi
    fi
  else
    if whip_yesno "JA" "NEIN" "${whip_title}" "Nutzt Du ein NAS in deinem Netzwerk?"; then
      if check_ip; then
        nas_exist=true
        nas_ip=${ip}
      else
        nas_exist=false
        nas_ip=
      fi
    fi
  fi
  if ${nas_exist}; then
    menu_nas=("1" "... Synology" \
              "2" "... QNAP"\
              "3" "... andere/keine")
    nas_manufactur=$(whiptail --menu --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${whip_title} " "\nMein NAS Hersteller heisst..." 20 80 10 "${menu_nas[@]}" 3>&1 1>&2 2>&3)
    if [ $nas_manufactur -eq 1 ]; then
      nas_synology=true
      nas_qnap=false
    elif [ $nas_manufactur -eq 2 ]; then
      nas_synology=false
      nas_qnap=true
    else
      nas_synology=false
      nas_qnap=false
    fi
  fi
}

function smtp() {
# config SMTP server for email notification
  if $update; then
    mail_rootadress=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die E-Mailadresse, an die Benachrichtigungen gesendet werden sollen?" "$(echo ${mail_rootadress})")
  else
    mail_rootadress=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die E-Mailadresse, an die Benachrichtigungen gesendet werden sollen?" "$(pveum user list | grep 'root@pam' | awk '{print $5}')")
  fi
  if $update; then
    mail_senderaddress=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die E-Mailadresse, von der Benachrichtigungen gesendet werden sollen?" "$(echo ${mail_senderaddress})")
  else
    mail_senderaddress=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die E-Mailadresse, von der Benachrichtigungen gesendet werden sollen?" "notify@$(echo ${mail_rootadress} | cut -d\@ -f2)")
  fi
  if $update; then
    mail_server=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die Adresse deines Mailserver?" "$(echo ${mail_server})")
  else
    mail_server=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die Adresse deines Mailserver?" "smtp.$(echo ${mail_rootadress} | cut -d\@ -f2)")
  fi
  if $update; then
    mail_port=$(whip_inputbox "OK" "${whip_title}" "Welcher Port soll für deinen Mailserver verwendet werden?" "$(echo ${mail_port})")
  else
    mail_port=$(whip_inputbox "OK" "${whip_title}" "Welcher Port soll für deinen Mailserver verwendet werden?" "587")
  fi
  if whip_yesno "JA" "NEIN" "${whip_title}" "Benötigt dein Mailserver für den Login TLS/STARTTLS?"; then
    mail_tls=yes
  else
    mail_tls=no
  fi

  if $update; then
    mail_user=$(whip_inputbox "OK" "${whip_title}" "Welcher Benutzername wird für den Login am Mailserver verwendet?" "$(echo ${mail_user})")
  else
    mail_user=$(whip_inputbox "OK" "${whip_title}" "Welcher Benutzername wird für den Login am Mailserver verwendet?" "$(pveum user list | grep 'root@pam' | awk '{print $5}')")
  fi
  if $update; then
    mail_password=$(whip_inputbox_password "OK" "${whip_title}" "Wie lautet das Passwort, welches für den Login am Mailserver verwendet wird?" "$(echo ${mail_password})")
  else
    mail_password=$(whip_inputbox_password "OK" "${whip_title}" "Wie lautet das Passwort, welches für den Login am Mailserver verwendet wird?")
  fi
}

function write_configfile() {
# Write Mainconfig File

  # ask the user if the passwords should be saved in the configuration file
  if whip_yesno "JA" "NEIN" "${whip_title}" "Sollen deine Passwörter unverschlüsselt im Klartext in der Konfigurationsdatei gespeichert werden (unsicher)?"; then
    safe_pw=true
  else
    safe_pw=false
  fi

  # Generate mainconfig File
  if [ -f "${config_path}/${config_file}" ]; then rm "${config_path}/${config_file}"; fi
  echo -e "\0043\0041/bin/bash" > "${config_path}/${config_file}"
  echo -e "\0043 NOTICE: Backup Proxmox Configuration Script from SmartHome-IoT.net" >> "${config_path}/${config_file}"
  echo -e "\0043 Created on $(date)" >> "${config_path}/${config_file}"
  echo -e "\n\0043 General configuration" >> "${config_path}/${config_file}"
  echo -e "config_version=${version_mainconfig}" >> "${config_path}/${config_file}"
  echo -e "main_language=${main_language}" >> "${config_path}/${config_file}"
  if whip_yesno "heller Modus" "dunkler Modus" "Proxmox WebGUI" "Möchtest du den Darkmode in Proxmox aktivieren?\n weitere Infos unter https://github.com/Weilbyte/PVEDiscordDark"; then
    echo -e "darkmode=false" >> "${config_path}/${config_file}"
    bash <(curl -s https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh) --silent status
    if [ $? -eq 0 ]; then bash <(curl -s https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh) --silent uninstall; fi
  else
    echo -e "darkmode=true" >> "${config_path}/${config_file}"
    bash <(curl -s https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh) --silent status
    if [ $? -eq 1 ]; then bash <(curl -s https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh) --silent install; fi
  fi
  echo -e "\n\0043 Network configuration" >> "${config_path}/${config_file}"
  echo -e "network_ip=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1 | cut -d. -f1,2,3)" >> "${config_path}/${config_file}"
  echo -e "network_gateway=$(ip r | grep default | cut -d" " -f3)" >> "${config_path}/${config_file}"
  echo -e "network_cidr=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f2)" >> "${config_path}/${config_file}"
  echo -e "network_domainname=$(hostname -f | cut -d. -f2,3)" >> "${config_path}/${config_file}"
  echo -e "network_adapter0=$(cat /etc/network/interfaces | grep bridge-ports | cut -d" " -f2)" >> "${config_path}/${config_file}"
  if [ $(cat /etc/network/interfaces | grep bridge-ports | cut -d" " -f2 | grep -v ${network_adapter0} | wc -l) -gt 0 ]; then
    i=0
    for card in $(cat /etc/network/interfaces | grep bridge-ports | cut -d" " -f2 | grep -v enp4s7 | sed ':M;N;$!bM;s|\n| |g'); do
      i=$(( $i + 1 ))
      echo -e "network_adapter${i}=${card}" >> "${config_path}/${config_file}"
    done
  fi
  echo -e "\n\0043 VLAN configuration" >> "${config_path}/${config_file}"
  if $vlan_available; then
    echo -e "vlan_available=true" >> "${config_path}/${config_file}"
    if [ -z "${vlan_unifi_gw}" ]; then
      echo -e "vlan_unifi_id=1" >> "${config_path}/${config_file}"
      echo -e "vlan_unifi_net=$(echo ${vlan_unifi_gw} | cut -d. -f1,2,3)" >> "${config_path}/${config_file}"
      echo -e "vlan_unifi_gw=${vlan_unifi_gw}" >> "${config_path}/${config_file}"
      echo -e "vlan_unifi_cidr=24" >> "${config_path}/${config_file}"
    fi
    echo -e "vlan_productive_id=${vlan_productive_id}" >> "${config_path}/${config_file}"
    echo -e "vlan_productive_net=$(echo ${vlan_productive_gw} | cut -d. -f1,2,3)" >> "${config_path}/${config_file}"
    echo -e "vlan_productive_gw=${vlan_productive_gw}" >> "${config_path}/${config_file}"
    echo -e "vlan_productive_cidr=${vlan_productive_cidr}" >> "${config_path}/${config_file}"
    echo -e "vlan_iot_id=${vlan_iot_id}" >> "${config_path}/${config_file}"
    echo -e "vlan_iot_net=$(echo ${vlan_iot_gw} | cut -d. -f1,2,3)" >> "${config_path}/${config_file}"
    echo -e "vlan_iot_gw=${vlan_iot_gw}" >> "${config_path}/${config_file}"
    echo -e "vlan_iot_cidr=${vlan_iot_cidr}" >> "${config_path}/${config_file}"
    echo -e "vlan_guest_id=${vlan_guest_id}" >> "${config_path}/${config_file}"
    echo -e "vlan_guest_net=$(echo ${vlan_guest_gw} | cut -d. -f1,2,3)" >> "${config_path}/${config_file}"
    echo -e "vlan_guest_gw=${vlan_guest_gw}" >> "${config_path}/${config_file}"
    echo -e "vlan_guest_cidr=${vlan_guest_cidr}" >> "${config_path}/${config_file}"
    vlan_other=$(cat "${tmp_vlan}")
    if [ -n "${vlan_other}" ]; then
      echo -e "vlan_other=true" >> "${config_path}/${config_file}"
      echo $(echo $vlan_other | sed -e 's/\t\| \+/\n/g') >> "${config_path}/${config_file}"
    else
      echo -e "vlan_other=false" >> "${config_path}/${config_file}"
    fi
  else
    echo -e "vlan_available=false" >> "${config_path}/${config_file}"
    echo -e "vlan_unifi_id=" >> "${config_path}/${config_file}"
    echo -e "vlan_unifi_net=" >> "${config_path}/${config_file}"
    echo -e "vlan_unifi_gw=" >> "${config_path}/${config_file}"
    echo -e "vlan_unifi_cidr=" >> "${config_path}/${config_file}"
    echo -e "vlan_productive_id=" >> "${config_path}/${config_file}"
    echo -e "vlan_productive_net=" >> "${config_path}/${config_file}"
    echo -e "vlan_productive_gw=" >> "${config_path}/${config_file}"
    echo -e "vlan_productive_cidr=" >> "${config_path}/${config_file}"
    echo -e "vlan_iot_id=" >> "${config_path}/${config_file}"
    echo -e "vlan_iot_net=" >> "${config_path}/${config_file}"
    echo -e "vlan_iot_gw=" >> "${config_path}/${config_file}"
    echo -e "vlan_iot_cidr=" >> "${config_path}/${config_file}"
    echo -e "vlan_guest_id=" >> "${config_path}/${config_file}"
    echo -e "vlan_guest_net=" >> "${config_path}/${config_file}"
    echo -e "vlan_guest_gw=" >> "${config_path}/${config_file}"
    echo -e "vlan_guest_cidr=" >> "${config_path}/${config_file}"
    echo -e "vlan_other=false" >> "${config_path}/${config_file}"
  fi
  echo -e "\n\0043 Netrobot configuration" >> "${config_path}/${config_file}"
  echo -e "robot_name=${robot_name}" >> "${config_path}/${config_file}"
  if $safe_pw; then
    echo -e "robot_pw=\"${robot_pw}\"" >> "${config_path}/${config_file}"
  else
    echo -e "robot_pw=" >> "${config_path}/${config_file}"
  fi
  echo -e "\n\0043 Mailserver configuration" >> "${config_path}/${config_file}"
  echo -e "mail_rootadress=${mail_rootadress}" >> "${config_path}/${config_file}"
  echo -e "mail_senderaddress=${mail_senderaddress}" >> "${config_path}/${config_file}"
  echo -e "mail_server=${mail_server}" >> "${config_path}/${config_file}"
  echo -e "mail_port=${mail_port}" >> "${config_path}/${config_file}"
  echo -e "mail_tls=${mail_tls}" >> "${config_path}/${config_file}"
  echo -e "mail_user=${mail_user}" >> "${config_path}/${config_file}"
  if $safe_pw; then
    echo -e "mail_password=\"${mail_password}\"" >> "${config_path}/${config_file}"
  else
    echo -e "mail_password=" >> "${config_path}/${config_file}"
  fi
  echo -e "\n\0043 NAS configuration" >> "${config_path}/${config_file}"
  echo -e "nas_exist=${nas_exist}" >> "${config_path}/${config_file}"
  echo -e "nas_ip=${nas_ip}" >> "${config_path}/${config_file}"
  echo -e "nas_synology=${nas_synology}" >> "${config_path}/${config_file}"
  echo -e "nas_qnap=${nas_qnap}" >> "${config_path}/${config_file}"
  echo -e "\n\0043 Hostsystem configuration (Proxmox)" >> "${config_path}/${config_file}"
  echo -e "pve_hostname=$(hostname)" >> "${config_path}/${config_file}"
  echo -e "pve_majorversion=$(pveversion | cut -d/ -f2 | cut -d. -f1)" >> "${config_path}/${config_file}"
  echo -e "pve_version=$(pveversion | cut -d/ -f2 | cut -d- -f1)" >> "${config_path}/${config_file}"
  echo -e "pve_versioncode=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d= -f2)" >> "${config_path}/${config_file}"
  echo -e "pve_ip=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1)" >> "${config_path}/${config_file}"
  echo -e "pve_timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')" >> "${config_path}/${config_file}"
  echo -e "pve_rootdisk=$(eval $(lsblk -oMOUNTPOINT,PKNAME -P | grep 'MOUNTPOINT="/"'); echo $PKNAME | sed 's|[0-9]*$||')" >>  "${config_path}/${config_file}"
  if [[ $(cat /sys/block/$(lsblk -nd --output NAME | grep "sd" | sed "s|$pve_rootdisk||" | sed ':M;N;$!bM;s|\n||g')/queue/rotational) -eq 0 ]]; then
    echo -e "pve_datadisk=$(lsblk -nd --output NAME | grep "sd" | sed "s|$pve_rootdisk||" | sed ':M;N;$!bM;s|\n||g')" >> "${config_path}/${config_file}"
    echo -e "pve_datadiskname=data" >> "${config_path}/${config_file}"
  else
    echo -e "pve_datadisk=" >> "${config_path}/${config_file}"
    echo -e "pve_datadiskname=local" >> "${config_path}/${config_file}"
  fi
}

function config() {
  echoLOG b "Beginne mit der Proxmox Basiskonfiguration"
  # enable S.M.A.R.T.-Support on root disk if available and disabled
  if ! ${update}; then
    echoLOG b "Aktiviere S.M.A.R.T. auf der Systemfestplatte"
    if [ $(smartctl -a /dev/${pve_rootdisk} | grep -c "SMART support is: Available") -eq 1 ] && [ $(smartctl -a /dev/${pve_rootdisk} | grep -c "SMART support is: Disabled") -eq 1 ]; then
      smartctl -s on -a /dev/${pve_rootdisk} > /dev/null 2>&1
    fi
  fi

  # if available, config second SSD as data Storage
  if [ -n "${pve_datadisk}" ]; then
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
      echoLOG b "Aktiviere S.M.A.R.T. auf der zweiten Festplatte"
      smartctl -s on -a /dev/${pve_datadiskname} > /dev/null 2>&1
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
      backups --server ${nas_ip} --share backups --username "${robot_name}" --password "${mail_password}" --content backup
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
      sed -i "s/^root:.*$/root: ${mail_rootadress}/" /etc/aliases > /dev/null 2>&1
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
    postconf smtp_use_tls=${mail_tls}
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
    systemctl restart postfix  > /dev/null 2>&1 && systemctl enable postfix  > /dev/null 2>&1
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
  echo -e "[OPTIONS]\nenable: 1\n" >> ${fw_cluster_file}
  ##All private Networks
  echo -e "[IPSET private] \0043 Alle privaten Netzwerke, wichtig für VPN\n10.0.0.0/8\n172.16.0.0/12\n192.168.0.0/16\n" >> ${fw_cluster_file}
  if $vlan_available; then
    if [ -z "${vlan_unifi_gw}" ]; then
      echo -e "[IPSET unifi] \0043 Ubiquiti/UniFi Netzwerk\n${vlan_unifi_net}.0/${vlan_unifi_cidr} \0043 UniFi Netzwerk\n" >> ${fw_cluster_file}
    fi
    echo -e "[IPSET productive] \0043 Produktiv-Netzwerk (VLAN-ID ${vlan_productive_id})\n${vlan_productive_net}.0/${vlan_productive_cidr} \0043 VLAN-ID ${vlan_productive_id}\n" >> ${fw_cluster_file}
    echo -e "[IPSET iot] \0043 IoT-Netzwerk (VLAN-ID ${vlan_iot_id})\n${vlan_iot_net}.0/${vlan_iot_cidr} \0043 VLAN-ID ${vlan_iot_id}\n" >> ${fw_cluster_file}
    echo -e "[IPSET guest] \0043 Gäste-Netzwerk (VLAN-ID ${vlan_guest_id})\n${vlan_guest_net}.0/${vlan_guest_cidr} \0043 VLAN-ID ${vlan_guest_id}\n" >> ${fw_cluster_file}
    if $vlan_other; then
      vlan_is_count=$(cat "${config_path}/${config_file}" | grep 'vlan_.*id_' | cut -d_ -f4 | cut -d= -f1 | tail -n1)
      for N in $(seq 1 ${vlan_is_count}); do
        name="$(cat "${config_path}/${config_file}" | grep "vlan_.*id_${N}" | cut -d_ -f2 | cut -d= -f1)"
        echo -e "[IPSET ${name}] \0043 ${name}-Netzwerk (VLAN-ID $(cat "${config_path}/${config_file}" | grep "vlan_.*id_${N}" | cut -d= -f2)\n$(cat "${config_path}/${config_file}" | grep "vlan_.*net_${N}" | cut -d= -f2 | cut -d. -f1,2,3)/$(cat "${config_path}/${config_file}" | grep "vlan_.*cidr_${N}" | cut -d= -f2) \0043 VLAN-ID $(cat "${config_path}/${config_file}" | grep "vlan_.*id_${N}" | cut -d= -f2)\n" >> ${fw_cluster_file}
      done
    fi
    ###Create loggical IP-Sets
    if [ -z "${vlan_unifi_gw}" ]; then
      echo -e "[IPSET unifi-productive] \0043 Ubiquiti/UniFi- und Produktiv-Netzwerk\n${vlan_unifi_net}.0/${vlan_unifi_cidr} \0043 UniFi Netzwerk\n${vlan_productive_net}.0/${vlan_productive_cidr} \0043 VLAN-ID ${vlan_productive_id}\n" >> ${fw_cluster_file}
      echo -e "[IPSET unifi-iot] \0043 Ubiquiti/UniFi- und IoT-Netzwerk\n${vlan_unifi_net}.0/${vlan_unifi_cidr} \0043 UniFi Netzwerk\n${vlan_iot_net}.0/${vlan_iot_cidr} \0043 VLAN-ID ${vlan_iot_id}\n" >> ${fw_cluster_file}
      echo -e "[IPSET unifi-productive-iot] \0043 Ubiquiti/UniFi-, Produktiv- und IoT-Netzwerk\n${vlan_unifi_net}.0/${vlan_unifi_cidr} \0043 UniFi Netzwerk\n${vlan_productive_net}.0/${vlan_productive_cidr} \0043 VLAN-ID ${vlan_productive_id}\n${vlan_iot_net}.0/${vlan_iot_cidr} \0043 VLAN-ID ${vlan_iot_id}\n" >> ${fw_cluster_file}
    fi 
    echo -e "[IPSET productive-iot] \0043 Produktiv- und IoT-Netzwerk (VLAN-IDs ${vlan_productive_id} und ${vlan_iot_id})\n${vlan_productive_net}.0/${vlan_productive_cidr} \0043 VLAN-ID ${vlan_productive_id}\n${vlan_iot_net}.0/${vlan_iot_cidr} \0043 VLAN-ID ${vlan_iot_id}\n" >> ${fw_cluster_file}
    echo -e "[IPSET productive-guest] \0043 Produktiv- und Gäste-Netzwerk (VLAN-IDs ${vlan_productive_id} und ${vlan_guest_id})\n${vlan_productive_net}.0/${vlan_productive_cidr} \0043 VLAN-ID ${vlan_productive_id}\n${vlan_guest_net}.0/${vlan_guest_cidr} \0043 VLAN-ID ${vlan_guest_id}\n" >> ${fw_cluster_file}
  else
    echo -e "[IPSET productive] \0043 Netzwerk\n${network_ip}.0/${network_cidr} \0043 eigener Netzwerkbereich\n" >> ${fw_cluster_file}
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
}

if [ ! -f "${config_path}/.config" ]; then
  whip_title_fr="ERSTSTART"
  if whip_alert_yesno "RECOVER" "KONFIG" "${whip_title_fr}" "Soll dieser Server neu konfiguriert werden, oder möchtest Du eine gesicherte Konfigurationsdatei laden (Recovery)?"; then
    if [ ! -d "/mnt/cfg_temp" ]; then mkdir -p "/mnt/cfg_temp"; fi
    if whip_yesno "FREIGABE" "LOKAL" "${whip_title_fr}" "Wo befindet sich die Konfigurationsdatei? (Netzfreigabe z.B. NAS, PC oder lokal z.B. USB-Stick, Server)"; then # Mount Network Share and copy File
      if ! check_ip; then
        if whip_alert_yesno "Beenden" "Erstellen" "${whip_title_fr}" "Die wiederherstellung der Konfigurationsdatei von deinem Netzwerkgerät wurde auf Deinen Wunsch abgebrochen. Möchtest Du dieses Script beenden, oder eine neue Konfigurationsdatei erstellen?"
          exit 1
        fi
        mountUser=$(whip_inputbox "OK" "${whip_title_fr}" "Wie lautet der Benutzername des Benutzers der Leserechte auf dieser Freigabe hat?" "netrobot")
        mountPass=$(whip_inputbox_password "OK" "${whip_title_fr}" "Wie lautet das Passwort von diesem Benutzer?")
        mount -t cifs -o user="${mountUser}",password="${mountPass}",rw,file_mode=0777,dir_mode=0777 "//${ip}" "/mnt/cfg_temp" > /dev/null 2>&1
        mnt=true
      else
        if whip_yesno "DATENTRÄGER" "SERVER" "${whip_title_fr}" "Hast Du die Datei schon auf deinen HomeServer kopiert, oder befindet sie sich auf einem externen Datenträger?"; then # Mount USB Media and copy File
        ext_disk=$(whip_inputbox "OK" "${whip_title_fr}" "Wie lautet der Pfad zu deinem USB-Gerät? (siehe WebGUI -> Server -> Disks)" "/dev/sdc")
        mount $ext_disk "/mnt/cfg_temp"
        mnt=true
      fi
    fi
    if ${mnt}; then 
      whip_filebrowser "/mnt/cfg_temp/"
    else
      whip_filebrowser "/root/"
    fi
    source "${filepath}/${filename}"
  else
    echoLOG b "Konfigurationsdatei wird erstellt"
    vlan
    netrobot
    nas
    smtp
    write_configfile
  fi
fi

if $update; then
  echoLOG b "Die Konfigurationsdatei wird aktualisiert"
  vlan
  netrobot
  nas
  smtp
  write_configfile
  if [ ! -f "${config_path}/${config_file}" ]; then
    whip_alert "${whip_title}" "Die Konfiguratoinsdatei konnte nicht aktualisiert werden"
    exit 1
  fi
  echoLOG g "Die Konfigurationsdatei wurde erfolgreich aktualisiert"
fi

if [ -f "${config_path}/${config_file}" ]; then
  echoLOG b "Konfiguriere deinen Proxmox HomeServer"
  if ! config; then
    echoLOG r "Deine Proxmox Serverkonfiguration konnte nicht erfolgreich durchgeführt werden"
    exit 1
  fi
fi

exit 0
