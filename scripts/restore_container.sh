#!/bin/bash
#
# Restore manual Backups from Container

#Load needed Files
source "${script_path}/sources/functions.sh"  # Functions needed in this Script
source "${script_path}/sources/variables.sh"  # Variables needed in this Script
source "${config_path}/${config_file}"        # Loads Mainconfig File
source "${script_path}/language/${main_language}.sh"   # Language Variables in this Script

whip_title="CONTAINER WIEDERHERSTELLEN"

# Check if there are manual backups
if ! ls /mnt/pve/backups/dump/*_manual.tar.zst 1> /dev/null 2>&1; then
  whip_alert "${whip_title}" "Es wurden keine manuellen Container Backups gefunden. Es gibt nichts von dem ein Container wiederhergestellt werden könnte."
  exit 1
fi

for lxc in $(ls -l /mnt/pve/backups/dump/*_manual.tar.zst | awk '{print $9}' | cut -d- -f3); do
  id=100
  name=$(ls -l /mnt/pve/backups/dump/*${lxc}*_manual.tar.zst | awk '{print $9}' | cut -d- -f4 | cut -d_ -f1)
  new=true
  if [ $(pct list | tail -n +2 | wc -l) -gt 0 ]; then
    new=falsee
    name="${name}-recover"
    #search the next free id
    while [ $(pct list | grep -c ${id} ) -eq 1 ]; do
      id=$(( ${id} + 1 ))
    done
  fi
  if pct restore ${id} /mnt/pve/backups/dump/*-${lxc}-*_manual.tar.zst --storage ${pve_datadiskname} --pool "BackupPool" --force 1 > /dev/null 2>&1; then
    if ! ${new}; then pct set ${id} --hostname "${name}"; fi
    echoLOG g "Das Gastsystem wurde erfolgreich wiederhergestellt >> ID: ${LIGHTPURPLE}${id}${NOCOLOR}  Name: ${LIGHTPURPLE}${name}${NOCOLOR}"
  else
    whip_alert "${whip_title}" "Das gewünschte Gastsystem konnte nicht wiederhergestellt werden\nID:   ${id}\nName: ${name}"
  fi
done

exit 0
