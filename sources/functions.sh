#!/bin/bash

# Function ping given IP and return TRUE if available
function pingIP() {
  if ping -c 1 $1 &> /dev/null; then
    true
  else
    false
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
    if ! apt-get install 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n25\nSystemupdate wird ausgeführt ...\nXXX"
    if ! apt-get upgrade -y 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n47\nSystemupdate wird ausgeführt ...\nXXX"
    if ! apt-get dist-upgrade -y 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n64\nSystemupdate wird ausgeführt ...\nXXX"
    if ! apt-get autoremove -y 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n79\nSystemupdate wird ausgeführt ...\nXXX"
    if ! pveam update 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n98\nSystemupdate wird ausgeführt ...\nXXX"
  } | whiptail --gauge --backtitle "© 2021 - SmartHome-IoT.net" --title " SYSTEMVORBEREITUNG " "Dein HomeServer wird auf Systemupdates geprüft ..." 10 80 0
  return true
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
  
  if [ ! -d "${config_path}" ]; then mkdir -p "${config_path}"; fi
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
    whiptail --msgbox --ok-button " OK " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${1} " "${2}" 0 80
    echoLOG r "${message}"
}

# give an whiptail message box
function whip_message() {
  #call whip_message "title" "message"
  whiptail --msgbox --ok-button " OK " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${1} " "${2}" 0 80
  echoLOG b "${message}"
}

function whip_alert_yesno() {
  #call whip_alert_yesno "btn1" "btn2" "title" "message"  >> btn1 = true  btn2 = false
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --yesno --yes-button " ${1} " --no-button " ${2} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${3} " "${4}" 0 80
    yesno=$?
    if [ ${yesno} -eq 0 ]; then echoLOG r "${4} ${blue}${1}${nc}"; else echoLOG r "${4} ${blue}${2}${nc}"; fi
    if [ ${yesno} -eq 0 ]; then true; else false; fi
}

# Functions shows Whiptail
function whip_yesno() {
  #call whip_yesno "btn1" "btn2" "title" "message"  >> btn1 = true  btn2 = false
  whiptail --yesno --yes-button " ${1} " --no-button " ${2} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${3} " "${4}" 0 80
  yesno=$?
  if [ ${yesno} -eq 0 ]; then true; else false; fi
}

function whip_inputbox() {
  #call whip_inputbox "btn" "title" "message" "default value"
  input=$(whiptail --inputbox --ok-button " ${1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${2} " "\n${3}" 0 80 "${4}" 3>&1 1>&2 2>&3)
  if [[ $input == "" ]]; then
    whip_inputbox "$1" "$2" "$3" "$4\n\n!!! Es muss eine Eingabe erfolgen !!!" ""
  else
    echo "${input}"
  fi
}

function whip_alert_inputbox() {
  #call whip_inputbox "btn" "title" "message" "default value"
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
  input=$(whiptail --inputbox --ok-button " ${1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${2} " "\n${3}" 0 80 "${4}" 3>&1 1>&2 2>&3)
  if [[ $input == "" ]]; then
    whip_inputbox "$1" "$2" "$3" "$4\n\n!!! Es muss eine Eingabe erfolgen !!!" ""
  else
    echo "${input}"
  fi
}

function whip_inputbox_cancel() {
  #call whip_inputbox_cancel "btn1" "btn2" "title" "message" "default value"
  input=$(whiptail --inputbox --ok-button " ${1} " --cancel-button " ${2} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${3} " "\n${4}" 0 80 "${5}" 3>&1 1>&2 2>&3)
  if [ $? -eq 1 ]; then
    echo cancel
  else
    if [[ $input == "" ]]; then
      whip_inputbox_cancel "$1" "$2" "$3" "$4\n\n!!! Es muss eine Eingabe erfolgen !!!" ""
    else
      echo "${input}"
    fi
  fi
}

function whip_alert_inputbox_cancel() {
  #call whip_inputbox_cancel "btn1" "btn2" "title" "message" "default value"
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
  input=$(whiptail --inputbox --ok-button " ${1} " --cancel-button " ${2} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${3} " "\n${4}" 0 80 "${5}" 3>&1 1>&2 2>&3)
  if [ $? -eq 1 ]; then
    echo cancel
  else
    if [[ $input == "" ]]; then
      whip_inputbox_cancel "$1" "$2" "$3" "$4\n\n!!! Es muss eine Eingabe erfolgen !!!" ""
    else
      echo "${input}"
    fi
  fi
}

function whip_inputbox_password() {
  #call whip_inputbox "btn" "title" "message"
  input=$(whiptail --passwordbox --ok-button " ${1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${2} " "\n${3}" 10 80 3>&1 1>&2 2>&3)
  if [[ $input == "" ]]; then
    whip_inputbox "$1" "$2" "$3" "$4\n\n!!! Es muss eine Eingabe erfolgen !!!" ""
  else
    echo "${input}"
  fi
}

function whip_filebrowser() {
  #call whip_filebrowser "startpath"
  #returns $filename and $filepath
  if [ -z $1 ] ; then
    dir_list=$(ls -lhp | grep "^d" | awk '{print $9 "  " $7 $6 "-" $8}' && ls -lhp | grep -v "^d" | grep -v "^l" | grep -v "^total" | awk '{print $9 "  " $7 $6 "-" $8}')
  else
    cd "$1"
    dir_list=$(ls -lhp | grep "^d" | awk '{print $9 "  " $7 $6 "-" $8}' && ls -lhp | grep -v "^d" | grep -v "^l" | grep -v "^total" | awk '{print $9 "  " $7 $6 "-" $8}')
  fi

  curdir=$(pwd)
  if [ "$curdir" == "/" ] ; then  # Check if current dir is root folder
    selection=$(whiptail --menu --ok-button " Select " --cancel-button " Cancel " --backtitle "© 2021 - SmartHome-IoT.net" --title " Dateiauswahl " "Aktueller Pfad\n$curdir" 0 80 0 $dir_list 3>&1 1>&2 2>&3)
  else   # Not root dir so show ../ selection in Menu
    selection=$(whiptail --menu --ok-button " Select " --cancel-button " Cancel " --backtitle "© 2021 - SmartHome-IoT.net" --title " Dateiauswahl " "Aktueller Pfad\n$curdir" 0 80 0 ../ " " $dir_list 3>&1 1>&2 2>&3)
  fi

  RET=$?
  if [ $RET -eq 1 ]; then return 1; fi  # Check if User selected cancel
  
  if [[ -d "$selection" ]]; then  # Check if Directory selected
    whip_filebrowser "$selection"
  elif [[ -f "$selection" ]]; then  # Check if File selected
    if file --mime-type "$selection" | grep -q text; then  # Check if selected File can read as Text-File
      if (whip_yesno "Bestätigen" "Wiederholen" "Auswahl bestätigen" "Pfad     : $curdir\nDateiname: $selection"); then
        filename="$selection"
        filepath="$curdir"    # Return full filepath and filename as selection variables
      else
        whip_filebrowser "$curdir"
      fi
    else   # Not correct fileselection so inform User and restart fileselection
      whip_alert "ERROR" "Du musst eine Datei wählen, dieals Text-Datei gelesenwerden kann (z.B. *.sh oder *.txt)\n$selection"
      whip_filebrowser "$curdir"
    fi
  else
    # Could not detect a file or folder so Try Again
    whip_alert "ERROR" "Fehler beim Wechseln zum Pfad\n$selection"
    whip_filebrowser "$curdir"
  fi
}

function check_ip() {
  if [ -n $1 ]; then ip="$1"; else ip=""; fi
  while ! pingIP ${ip}; do
    ip=$(whip_alert_inputbox_cancel "OK" "Abbrechen" "${whip_title_fr}" "Die angegebene IP-Adresse kann nicht gefunden werden, bitte prüfen und noch einmal versuchen!" "$(echo ${ip})")
    RET=$?
    if [ $RET -eq 1 ]; then return 1; fi  # Check if User selected cancel
  done
}

function package_exists() {
  if [ $(dpkg-query -s "${1}" &> /dev/null | grep -cw "Status: install ok installed") -eq 1 ]; then
    true
  else
    false
  fi
}

function lxc_mountNAS() {
  ############################################################
  echo "- Funktion lxc_mountNAS"
}

# Function configures SQL secure in LXC Containers
function lxc_SQLSecure() {
  ctID=${1}
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
