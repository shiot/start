#!/bin/bash
#
# Restore manual Backups from virtualMashines (VMs)

#Load needed Files
source "${script_path}/sources/functions.sh"  # Functions needed in this Script
source "${script_path}/sources/variables.sh"  # Variables needed in this Script
source "${config_path}/${config_file}"        # Loads Mainconfig File
source "${script_path}/language/${main_language}.sh"   # Language Variables in this Script

whip_title="VMs WIEDERHERSTELLEN"

# Check if there are already manual backups
if ! ls /mnt/pve/backups/dump/*_manual.vma.zst 1> /dev/null 2>&1; then
  whip_alert "${whip_title}" "Es wurden keine manuellen Backups von virtuellen Maschinen (VMs) gefunden. Es gibt nichts von dem eine virtuelle Maschine (VM) wiederhergestellt werden könnte."
  exit 1
fi

for vm in $(ls -l /mnt/pve/backups/dump/*_manual.vma.zst | awk '{print $9}' | cut -d- -f3); do
  id=200
  name=$(ls -l /mnt/pve/backups/dump/*${vm}*_manual.vma.zst | awk '{print $9}' | cut -d- -f4 | cut -d_ -f1)
  new=true
  if [ $(qm list | sed '1d' | grep -c "") -gt 0 ]; then
    new=falsee
    name="${name}-recover"
    #search the next free id
    while [ $(qm list | grep -c ${id} ) -eq 1 ]; do
      id=$(( ${id} + 1 ))
    done
  fi
  if qm restore ${id} /mnt/pve/backups/dump/*-${vm}-*_manual.vma.zst --storage ${pve_datadiskname} --pool "BackupPool" --force 1 > /dev/null 2>&1; then
    if ! ${new}; then qm set ${id} --name "${name}"; fi
    echoLOG g "Das Gastsystem wurde erfolgreich wiederhergestellt >> ID: ${LIGHTPURPLE}${id}${NOCOLOR}  Name: ${LIGHTPURPLE}${name}${NOCOLOR}"
  else
    whip_alert "${whip_title}" "Das gewünschte Gastsystem konnte nicht wiederhergestellt werden\nID:   ${id}\nName: ${name}"
  fi
done

exit 0
