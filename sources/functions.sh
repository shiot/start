#!/bin/bash

# Function ping given IP and return TRUE if available
function pingIP() {
  if ping -c 1 $1 &> /dev/null; then
    return 0
  else
    return 1
  fi
}

# Function get latest release from GitHub api
function githubLatest() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's|.*"([^"]+)".*|\1|'
}

# Function generates a random secure Linux password
function generatePassword() {
  chars=({0..9} {a..z} {A..Z} "_" "%" "+" "-" ".")
  for i in $(eval echo "{1..$1}"); do
    echo -n "${chars[$(($RANDOM % ${#chars[@]}))]}"
  done 
}

# Function generates a random API-Key
function generateAPIKey() {
  chars=({0..9} {a..f})
  for i in $(eval echo "{1..$1}"); do
    echo -n "${chars[$(($RANDOM % ${#chars[@]}))]}"
  done 
}

# Function update HomeServer (Host)
function updateHost() {
  {
    echo -e "XXX\n12\nSystemupdate wird ausgeführt ...\nXXX"
    apt-get update
    echo -e "XXX\n25\nSystemupdate wird ausgeführt ...\nXXX"
    apt-get upgrade -y
    echo -e "XXX\n47\nSystemupdate wird ausgeführt ...\nXXX"
    apt-get dist-upgrade -y
    echo -e "XXX\n64\nSystemupdate wird ausgeführt ...\nXXX"
    apt-get autoremove -y
    echo -e "XXX\n79\nSystemupdate wird ausgeführt ...\nXXX"
    pveam update 2>&1
    echo -e "XXX\n98\nSystemupdate wird ausgeführt ...\nXXX"
  } | whiptail --gauge --backtitle "© 2021 - SmartHome-IoT.net" --title " SYSTEMVORBEREITUNG " "Dein HomeServer wird auf Systemupdates geprüft ..." 10 80 0
  return 0
}

function bak_file() {
  mode=$1
  file=$2

  if [[ $mode == "backup" ]]; then
    cp "${file}" "${file}.bak"
  elif [[ $mode == "recover" ]]; then
    if [ -f "${file}.bak" ]; then
      rm "${file}"
      cp "${file}.bak" "${file}"
      rm "${file}.bak"
    else
      echoLOG r "Es wurde kein Dateibackup von ${file} gefunden. Die gewünschte Datei konnte nicht wiederhergestellt werden."
    fi
  fi
}

# Function clean the Shell History and exit
function cleanup_and_exit() {
  unset gh_tag
  unset main_language
  unset script_path
  cat /dev/null > ~/.bash_history && history -c && history -w
  sleep 5
  exit
}

# Function write event to logfile and echo colorized in shell
function echoLOG() {
  typ=$1
  text=$2
  nc='\033[0m'
  red='\033[1;31m'
  green='\033[1;32m'
  yellow='\033[1;33m'
  blue='\033[1;34m'
  
  if [ ! -d "/opt/smarthome-iot_net/" ]; then mkdir -p "/opt/smarthome-iot_net/"; fi
  if [ ! -f "${log_file}" ]; then touch "${log_file}"; fi
  
  if [[ $typ == "r" ]]; then
    echo -e "$(date +'%Y-%m-%d  %T')  [${red}ERROR${nc}]  $text"
    echo -e "$(date +'%Y-%m-%d  %T')  [ERROR]  $text" >> "${log_file}"
  elif [[ $typ == "g" ]]; then
    echo -e "$(date +'%Y-%m-%d  %T')  [${green}OK${nc}]     $text"
    echo -e "$(date +'%Y-%m-%d  %T')  [OK]     $text" >> "${log_file}"
  elif [[ $typ == "y" ]]; then
    echo -e "$(date +'%Y-%m-%d  %T')  [${yellow}WAIT${nc}]   $text"
    echo -e "$(date +'%Y-%m-%d  %T')  [WARTE]   $text" >> "${log_file}"
  elif [[ $typ == "b" ]]; then
    echo -e "$(date +'%Y-%m-%d  %T')  [${blue}INFO${nc}]   $text"
    echo -e "$(date +'%Y-%m-%d  %T')  [INFO]   $text" >> "${log_file}"
  fi
}

# give an whiptail alert message
function whip_alert() {
  #call whip_alert "title" "message"
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --msgbox --ok-button " OK " --backtitle "© 2021 - SmartHome-IoT.net" --title " $1 " "$2" 10 80
    echoLOG r "${message}"
}

function whip_alert_yesno() {
  #call whip_alert_yesno "btn1" "btn2" "title" "message"
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --yesno --yes-button " $1 " --no-button " $2 " --backtitle "© 2021 - SmartHome-IoT.net" --title " $3 " "$4" 10 80
    echoLOG r "${message}"
}

# Functions shows Whiptail
function whip_yesno() {
  #call whip_yesno "btn1" "btn2" "title" "message"
  whiptail --yesno --yes-button " $1 " --no-button " $2 " --backtitle "© 2021 - SmartHome-IoT.net" --title " $3 " "$4" 10 80
  yesno=$?
  if [ ${yesno} -eq 0 ]; then true; else false; fi
}

function whip_inputbox() {
  #call whip_inputbox "btn1" "title" "message" "default value"
  input=$(whiptail --inputbox --ok-button " $1 " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " $2 " "$3" 10 80 "$4" 3>&1 1>&2 2>&3)
  echo "$input"
}

function whip_inputbox_password() {
  #call whip_inputbox "btn1" "title" "message"
  input=$(whiptail --passwordbox --ok-button " $1 " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " $2 " "$3" 10 80 3>&1 1>&2 2>&3)
  echo "$input"
}

function lxc_mountNAS() {
  ############################################################
  echo "- Funktion lxc_mountNAS"
}

# Function configures SQL secure in LXC Containers
function lxc_SQLSecure() {
  ctID=$1
  SECURE_MYSQL=$(expect -c "
  set timeout 3
  spawn mysql_secure_installation
  expect \"Press y|Y for Yes, any other key for No:\"
  send \"n\r\"
  expect \"New password:\"
  send \"${ctRootPW}\r\"
  expect \"Re-enter new password:\"
  send \"${ctRootPW}\r\"
  expect \"Remove anonymous users?\"
  send \"y\r\"
  expect \"Disallow root login remotely?\"
  send \"y\r\"
  expect \"Remove test database and access to it?\"
  send \"y\r\"
  expect \"Reload privilege tables now?\"
  send \"y\r\"
  expect eof
  ")

  pct exec $ctID -- bash -ci "apt-get install -y expect > /dev/null 2>&1"
  pct exec $ctID -- bash -ci "echo \"${SECURE_MYSQL}\" > /dev/null 2>&1"
  pct exec $ctID -- bash -ci "apt-get purge -y expect > /dev/null 2>&1"
}
