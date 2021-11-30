#!/bin/bash
#
# Create the Mainconfiguration file, if the file exists, for example because a version
# update has to be executed, the file will be recreated

#Load needed Files
source "${script_path}/sources/functions.sh"  # Functions needed in this Script
source "${script_path}/sources/variables.sh"  # Variables needed in this Script
source "${script_path}/language/${main_language}.sh"   # Language Variables in this Script

# loads mainconfig file if exists
if [ -f "${config_path}/${config_file}" ]; then
  source "${config_path}/${config_file}"
  update=true
fi

whip_title="ERSTELLE/AKTUALISIERE KONFIGURATIONSDATEI"

function fristRun() {
  whip_title_fr="ERSTSTART"
  # configure Community Repository in Proxmox
  echoLOG b "Das Proxmox Repository von Enterprise zu Community geändert"
  echo "#deb https://enterprise.proxmox.com/debian/pve ${pve_osname} pve-enterprise" > /etc/apt/sources.list.d/pve-enterprise.list
  echo "deb http://download.proxmox.com/debian/pve ${pve_osname} pve-no-subscription" > /etc/apt/sources.list.d/pve-community.list

  {
  # Performs a system update and installs software required for this script
    apt-get update 2>&1 >/dev/null
    echo -e "XXX\n29\nInstalliere nicht vorhandene, benötigte Software Pakete ...\nXXX"
    apt-get install -y parted smartmontools libsasl2-modules mailutils git lxc-pve 2>&1 >/dev/null
    echo -e "XXX\n87\nInitiales Systemupdate wird ausgeführt ...\nXXX"
    apt-mark hold keyboard-configuration
    apt-get upgrade -y 2>&1 >/dev/null
    apt-get dist-upgrade -y 2>&1 >/dev/null
    apt-get autoremove -y 2>&1 >/dev/null
    apt-mark unhold keyboard-configuration
    pveam update 2>&1 >/dev/null
    echo -e "XXX\n98\nSystemvorbereitungen werden beendet ...\nXXX"
  } | whiptail --gauge --backtitle "© 2021 - SmartHome-IoT.net" --title " ${whip_title_fr} " "\nDein HomeServer wird auf Systemupdates geprüft, eventuell benötigte Software wird installiert ..." 10 80 0
  echoLOG g "Updates und benötigte Software wurden installiert"

  # If no Config File is found, ask User to recover or to make a new Configuration
  if [ ! -f "${shiot_configPath}/${shiot_configFile}" ]; then
    if whip_alert_yesno "RECOVER" "KONFIG" "${whip_title_fr}" "Soll dieser Server neu konfiguriert werden, oder möchtest Du eine gesicherte Konfigurationsdatei laden (Recovery)?"; then
      if [ ! -d "/mnt/cfg_temp" ]; then mkdir -p "/mnt/cfg_temp"; fi
      if whip_yesno "FREIGABE" "LOKAL" "${whip_title_fr}" "Wo befindet sich die Konfigurationsdatei? (Netzfreigabe z.B. NAS oder lokal z.B. USB-Stick, Server)"; then # Mount Network Share and copy File
        cfg_IP=
        while ! pingIP $cfg_IP; do
          cfg_IP=$(whip_inputbox "OK" "${whip_title_fr}" "Wie lautet die IP-Adresse des Gerätes, auf dem sich die Freigabe befindet?" "$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1 | cut -d. -f1,2,3).")
        done
        cfg_dir=$(whip_inputbox "OK" "${whip_title_fr}" "Wie lautet der Ordnerpfad, in dem die Datei zu finden ist (ohne \\ oder / am Anfang oder Ende)?" "Path/to/File")
        cfg_filename=$(whip_inputbox "OK" "${whip_title_fr}" "Wie heißt die Datei, die die Konfigurationsvariablen enthält?" "SHIoT_configuration.txt")
        cfg_mountUser=$(whip_inputbox "OK" "${whip_title_fr}" "Wie lautet der Benutzername des Benutzers der Leserechte auf dieser Freigabe hat?" "netrobot")
        cfg_mountPass=$(whip_inputbox_password "OK" "${whip_title_fr}" "Wie lautet das Passwort von diesem Benutzer?")
        mount -t cifs -o user="$cfg_mountUser",password="$cfg_mountPass",rw,file_mode=0777,dir_mode=0777 //$cfg_IP/$cfg_dir /mnt/cfg_temp > /dev/null 2>&1
        cp "/mnt/cfg_temp/$cfg_filename" "${config_path}/${config_file}" > /dev/null 2>&1
        umount "/mnt/cfg_temp" > /dev/null 2>&1
      else # ask for local or external file
        if whip_yesno "DATENTRÄGER" "SERVER" "${whip_title_fr}" "Hast Du die Datei schon auf deinen Server kopiert, oder befindet sie sich auf einem externen Datenträger?"; then # Mount USB Media and copy File
          cfg_disk=$(whip_inputbox "OK" "${whip_title_fr}" "Wie lautet der Pfad zu deinem USB-Gerät? (siehe WebGUI -> Server -> Disks)" "/dev/sdc")
          cfg_dir=$(whip_inputbox "OK" "${whip_title_fr}" "Wie lautet der Ordnerpfad, in dem die Datei zu finden ist (ohne \\ oder / am Anfang oder Ende)?" "Path/to/File")
          cfg_filename=$(whip_inputbox "OK" "${whip_title_fr}" "Wie heißt die Datei, die die Konfigurationsvariablen enthält?" "SHIoT_configuration.txt")
          mount $cfg_disk "/mnt/cfg_temp"
          cp "/mnt/cfg_temp/$cfg_dir/$cfg_filename" "${config_path}/${config_file}" > /dev/null 2>&1
          umount $cfg_disk
          echoLOG g "${txt_0019}: $cfg_disk/$cfg_dir"
        elif [ $yesno -eq 1 ]; then # copy File
          cfg_path=$(whip_inputbox "OK" "${whip_title_fr}" "${txt_0022}")
          cfg_filename=$(whip_inputbox "OK" "${whip_title_fr}" "${txt_0016}")
          cp "/$cfg_path/$cfg_filename" "${config_path}/${config_file}" > /dev/null 2>&1
        fi
      fi
      echoLOG g "Die Konfigurationsdatei wurde erfolgreich kopiert"
      rm "/mnt/cfg_temp/" > /dev/null 2>&1
    fi
  fi
}

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
      vlan_guest_cidr=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die Gateway-IP deines Gastnetzwerk?" "${vlan_guest_cidr}")
    else
      vlan_guest_cidr=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die Gateway-IP deines Gastnetzwerk?" "24")
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
    robot_name=$(whip_inputbox "OK" "${whip_title}" "Wie lautet der Benutzername, den Du deinem Netzwerkroboter zugewiesen hast?" "${robot_name}")
    robot_pw=$(whip_inputbox "OK" "${whip_title}" "Wie lautet das Passwort, welches Du deinem Netzwerkroboter zugewiesen hast?" "${robot_pw}")
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
      menu_nas=("1" "... Synology" \
                "2" "... QNAP"\
                "3" "... anderer")
      for N in $(seq 1 5); do
        nas_ip=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die IP-Adresse deiner NAS?" "${nas_ip}")
        if pingIP $nas_ip; then
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
          nas_exist=ture
          break
        fi
        if [ $N -eq 5 ]; then
          whip_alert "${whip_title}" "Es konnte keine Verbindung zu deiner NAS hergestellt werden."
          if whip_yesno "JA" "NEIN" "${whip_title}" "Möchtest du erneut versuchen Deine NAS einzubinden?"; then nas; fi
        fi
        nas_exist=false
      done
    fi
  else
    if whip_yesno "JA" "NEIN" "${whip_title}" "Hast Du eine NAS in deinem Netzwerk?"; then
      menu_nas=("1" "... Synology" \
                "2" "... QNAP"\
                "3" "... anderer")
      for N in $(seq 1 5); do
        nas_ip=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die IP-Adresse deiner NAS?" "$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1 | cut -d. -f1,2,3)")
        if pingIP ${nas_ip}; then
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
          nas_exist=ture
          break
        fi
        if [ $N -eq 5 ]; then
          whip_alert "${whip_title}" "Es konnte keine Verbindung zu deiner NAS hergestellt werden."
          if whip_yesno "JA" "NEIN" "${whip_title}" "Möchtest du erneut versuchen Deine NAS einzubinden?"; then nas; fi
        fi
        nas_exist=false
      done
    fi
  fi
}

function smtp() {
# config SMTP server for email notification
  if $update; then
    mail_rootadress=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die E-Mailadresse, an die Benachrichtigungen gesendet werden sollen?" "${mail_rootadress}")
  else
    mail_rootadress=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die E-Mailadresse, an die Benachrichtigungen gesendet werden sollen?" "$(pveum user list | grep 'root@pam' | awk '{print $5}')")
  fi
  if $update; then
    mail_senderaddress=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die E-Mailadresse, von der Benachrichtigungen gesendet werden sollen?" "${mail_senderaddress}")
  else
    mail_senderaddress=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die E-Mailadresse, von der Benachrichtigungen gesendet werden sollen?" "notify@$(echo ${mail_rootadress} | cut -d\@ -f2)")
  fi
  if $update; then
    mail_server=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die Adresse deines Mailserver?" "${mail_server}")
  else
    mail_server=$(whip_inputbox "OK" "${whip_title}" "Wie lautet die Adresse deines Mailserver?" "smtp.$(echo ${mail_rootadress} | cut -d\@ -f2)")
  fi
  if $update; then
    mail_port=$(whip_inputbox "OK" "${whip_title}" "Welcher Port soll für deinen Mailserver verwendet werden?" "${mail_port}")
  else
    mail_port=$(whip_inputbox "OK" "${whip_title}" "Welcher Port soll für deinen Mailserver verwendet werden?" "587")
  fi
  if whip_yesno "JA" "NEIN" "${whip_title}" "Benötigt dein Mailserver für den Login TLS/STARTTLS?"; then
    mail_tls=yes
  else
    mail_tls=no
  fi

  if $update; then
    mail_user=$(whip_inputbox "OK" "${whip_title}" "Welcher Benutzername wird für den Login am Mailserver verwendet?" "${mail_user}")
  else
    mail_user=$(whip_inputbox "OK" "${whip_title}" "Welcher Benutzername wird für den Login am Mailserver verwendet?" "$(pveum user list | grep 'root@pam' | awk '{print $5}')")
  fi
  if $update; then
    mail_password=$(whip_inputbox_password "OK" "${whip_title}" "Wie lautet das Passwort, welches für den Login am Mailserver verwendet wird?" "${mail_password}")
  else
    mail_password=$(whip_inputbox_password "OK" "${whip_title}" "Wie lautet das Passwort, welches für den Login am Mailserver verwendet wird?")
  fi
}

function write_config() {
# Write Mainconfig File

  # ask the user if the passwords should be saved in the configuration file
  if whip_yesno "JA" "NEIN" "${whip_title}" "Sollen deine Passwörter unverschlüsselt im Klartext in der Konfigurationsdatei gespeichert werden (Sicherheit beachten)?"; then
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
  echo -e "config_version=\"${version_mainconfig}\"" >> "${config_path}/${config_file}"
  echo -e "main_language=\"${main_language}\"" >> "${config_path}/${config_file}"
  echo -e "\n\0043 Network configuration" >> "${config_path}/${config_file}"
  echo -e "network_ip=\"$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1 | cut -d. -f1,2,3)\"" >> "${config_path}/${config_file}"
  echo -e "network_gateway=\"$(ip r | grep default | cut -d" " -f3)\"" >> "${config_path}/${config_file}"
  echo -e "network_cidr=\"$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f2)\"" >> "${config_path}/${config_file}"
  echo -e "network_domainname=\"$(hostname -f | cut -d. -f2,3)\"" >> "${config_path}/${config_file}"
  echo -e "network_adapter0=\"$(cat /etc/network/interfaces | grep bridge-ports | cut -d" " -f2)\"" >> "${config_path}/${config_file}"
  if [ $(cat /etc/network/interfaces | grep bridge-ports | cut -d" " -f2 | grep -v ${network_adapter0} | wc -l) -gt 0 ]; then
    i=0
    for card in $(cat /etc/network/interfaces | grep bridge-ports | cut -d" " -f2 | grep -v enp4s7 | sed ':M;N;$!bM;s|\n| |g'); do
      i=$(( $i + 1 ))
      echo -e "network_adapter${i}=\"${card}\"" >> "${config_path}/${config_file}"
    done
  fi
  echo -e "\n\0043 VLAN configuration" >> "${config_path}/${config_file}"
  if $vlan_available; then
    echo -e "vlan_available=true" >> "${config_path}/${config_file}"
    if [ -z "${vlan_unifi_gw}" ]; then
      echo -e "vlan_unifi_id=1" >> "${config_path}/${config_file}"
      echo -e "vlan_unifi_net=\"$(echo ${vlan_unifi_gw} | cut -d. -f1,2,3)\"" >> "${config_path}/${config_file}"
      echo -e "vlan_unifi_gw=\"${vlan_unifi_gw}\"" >> "${config_path}/${config_file}"
      echo -e "vlan_unifi_cidr=24" >> "${config_path}/${config_file}"
    fi
    echo -e "vlan_productive_id=${vlan_productive_id}" >> "${config_path}/${config_file}"
    echo -e "vlan_productive_net=\"$(echo ${vlan_productive_gw} | cut -d. -f1,2,3)\"" >> "${config_path}/${config_file}"
    echo -e "vlan_productive_gw=\"${vlan_productive_gw}\"" >> "${config_path}/${config_file}"
    echo -e "vlan_productive_cidr=\"${vlan_productive_cidr}\"" >> "${config_path}/${config_file}"
    echo -e "vlan_iot_id=${vlan_iot_id}" >> "${config_path}/${config_file}"
    echo -e "vlan_iot_net=\"$(echo ${vlan_iot_gw} | cut -d. -f1,2,3)\"" >> "${config_path}/${config_file}"
    echo -e "vlan_iot_gw=\"${vlan_iot_gw}\"" >> "${config_path}/${config_file}"
    echo -e "vlan_iot_cidr=\"${vlan_iot_cidr}\"" >> "${config_path}/${config_file}"
    echo -e "vlan_guest_id=${vlan_guest_id}" >> "${config_path}/${config_file}"
    echo -e "vlan_guest_net=\"$(echo ${vlan_guest_gw} | cut -d. -f1,2,3)\"" >> "${config_path}/${config_file}"
    echo -e "vlan_guest_gw=\"${vlan_guest_gw}\"" >> "${config_path}/${config_file}"
    echo -e "vlan_guest_cidr=\"${vlan_guest_cidr}\"" >> "${config_path}/${config_file}"
    vlan_other=$(cat "${tmp_vlan}")
    if [ -n $vlan_other ]; then
      echo -e "vlan_other=true" >> "${config_path}/${config_file}"
      echo $(cat "${tmp_vlan}") >> "${config_path}/${config_file}"
    else
      echo -e "vlan_other=false" >> "${config_path}/${config_file}"
    fi
  else
    echo -e "vlan_available=false" >> "${config_path}/${config_file}"
    echo -e "vlan_unifi_id=" >> "${config_path}/${config_file}"
    echo -e "vlan_unifi_net=\"\"" >> "${config_path}/${config_file}"
    echo -e "vlan_unifi_gw=\"\"" >> "${config_path}/${config_file}"
    echo -e "vlan_unifi_cidr=\"\"" >> "${config_path}/${config_file}"
    echo -e "vlan_productive_id=" >> "${config_path}/${config_file}"
    echo -e "vlan_productive_net=\"\"" >> "${config_path}/${config_file}"
    echo -e "vlan_productive_gw=\"\"" >> "${config_path}/${config_file}"
    echo -e "vlan_productive_cidr=\"\"" >> "${config_path}/${config_file}"
    echo -e "vlan_iot_id=" >> "${config_path}/${config_file}"
    echo -e "vlan_iot_net=\"\"" >> "${config_path}/${config_file}"
    echo -e "vlan_iot_gw=\"\"" >> "${config_path}/${config_file}"
    echo -e "vlan_iot_cidr=\"\"" >> "${config_path}/${config_file}"
    echo -e "vlan_guest_id=" >> "${config_path}/${config_file}"
    echo -e "vlan_guest_net=\"\"" >> "${config_path}/${config_file}"
    echo -e "vlan_guest_gw=\"\"" >> "${config_path}/${config_file}"
    echo -e "vlan_guest_cidr=\"\"" >> "${config_path}/${config_file}"
    echo -e "vlan_other=false" >> "${config_path}/${config_file}"
  fi
  echo -e "\n\0043 Netrobot configuration" >> "${config_path}/${config_file}"
  echo -e "robot_name=\"${robot_name}\"" >> "${config_path}/${config_file}"
  if $safe_pw; then
    echo -e "robot_pw=\"${robot_pw}\"" >> "${config_path}/${config_file}"
  else
    echo -e "robot_pw=\"\"" >> "${config_path}/${config_file}"
  fi
  echo -e "\n\0043 Mailserver configuration" >> "${config_path}/${config_file}"
  echo -e "mail_rootadress=\"${mail_rootadress}\"" >> "${config_path}/${config_file}"
  echo -e "mail_senderaddress=\"${mail_senderaddress}\"" >> "${config_path}/${config_file}"
  echo -e "mail_server=\"${mail_server}\"" >> "${config_path}/${config_file}"
  echo -e "mail_port=\"${mail_port}\"" >> "${config_path}/${config_file}"
  echo -e "mail_tls=\"${mail_tls}\"" >> "${config_path}/${config_file}"
  echo -e "mail_user=\"${mail_user}\"" >> "${config_path}/${config_file}"
  if $safe_pw; then
    echo -e "mail_password=\"${mail_password}\"" >> "${config_path}/${config_file}"
  else
    echo -e "mail_password=\"\"" >> "${config_path}/${config_file}"
  fi
  echo -e "\n\0043 NAS configuration" >> "${config_path}/${config_file}"
  echo -e "nas_exist=${nas_exist}" >> "${config_path}/${config_file}"
  echo -e "nas_ip=\"${nas_ip}\"" >> "${config_path}/${config_file}"
  echo -e "nas_synology=\"${nas_synology}\"" >> "${config_path}/${config_file}"
  echo -e "nas_qnap=\"${nas_qnap}\"" >> "${config_path}/${config_file}"
  echo -e "\n\0043 Hostsystem configuration (Proxmox)" >> "${config_path}/${config_file}"
  echo -e "pve_hostname=\"$(hostname)\"" >> "${config_path}/${config_file}"
  echo -e "pve_majorversion=\"$(pveversion | cut -d/ -f2 | cut -d. -f1)\"" >> "${config_path}/${config_file}"
  echo -e "pve_version=\"$(pveversion | cut -d/ -f2 | cut -d- -f1)\"" >> "${config_path}/${config_file}"
  echo -e "pve_versioncode=\"$(cat /etc/os-release | grep VERSION_CODENAME | cut -d= -f2)\"" >> "${config_path}/${config_file}"
  echo -e "pve_ip=\"$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1)\"" >> "${config_path}/${config_file}"
  echo -e "pve_timezone=\"$(timedatectl | grep "Time zone" | awk '{print $3}')\"" >> "${config_path}/${config_file}"
  echo -e "pve_rootdisk=\"$(eval $(lsblk -oMOUNTPOINT,PKNAME -P | grep 'MOUNTPOINT="/"'); echo $PKNAME | sed 's|[0-9]*$||')\"" >>  "${config_path}/${config_file}"
  if [[ $(cat /sys/block/$(lsblk -nd --output NAME | grep "s" | sed "s|$pve_rootdisk||" | sed ':M;N;$!bM;s|\n||g')/queue/rotational) -eq 0 ]]; then
    echo -e "pve_datadisk=\"$(lsblk -nd --output NAME | grep "s" | sed "s|$pve_rootdisk||" | sed ':M;N;$!bM;s|\n||g')\"" >> "${config_path}/${config_file}"
    echo -e "pve_datadiskname=\"data\"" >> "${config_path}/${config_file}"
  else
    echo -e "pve_datadisk=\"\"" >> "${config_path}/${config_file}"
    echo -e "pve_datadiskname=\"local\"" >> "${config_path}/${config_file}"
  fi
}

if [ ! -f "${config_path}/.config" ]; then fristRun; fi

vlan
netrobot
nas
smtp
write_config

exit 0

if [ -f "${config_path}/${config_file}" ]; then
  if $update; then
    echoLOG y "Aktualisiere deine Proxmox Serverkonfiguration"
    if bash "${script_path}/scripts/config_pve.sh" "update"; then
      echoLOG g "Deine Proxmox Serverkonfiguration wurde erfolgreich aktualisiert"
      exit 0
    else
      echoLOG r "Deine Proxmox Serverkonfiguration konnte nicht erfolgreich aktualisiert werden"
      exit 1
    fi
  else
    echoLOG y "Konfiguriere deinen Proxmox HomeServer"
    if bash "${script_path}/scripts/config_pve.sh"; then
      echoLOG g "Deine Proxmox Serverkonfiguration wurde erfolgreich durchgeführt"
      exit 0
    else
      echoLOG r "Deine Proxmox Serverkonfiguration konnte nicht erfolgreich durchgeführt werden"
      exit 1
    fi
  fi
else
  whip_alert "${whip_title}" "Die Konfiguratoinsdatei konnte nicht erstellt werden"
  exit 1
fi
