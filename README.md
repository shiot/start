### Deutsch
Starte dieses Skript, um die Welt Deines eigenen SmartHome zu betreten und mit der Konfiguration deines Proxmox Home Server zu beginnen.

Bitte benutze dieses Skript nur auf neu installierten Systemen. Wenn Du dieses Skript auf bereits konfigurierten und genutzten Servern einsetzt kann es zu schwerwiegenden Fehlern an deinem Serversystem nutzen. Mir ist es natürlich nicht möglich, dieses Skript auf allen nur erdenklichen Systemen zu testen, aus diesem Grund, kann ich für die richtige Funktion des Skript nicht Garantieren. Die Nutzung dieses Skript geschieht auf eigene Gefahr und Verantwortung. 

Ich habe dieses neue Repository aufgrund eurer Rückmeldungen erstellt und das Skript noch einmal komplett überarbeitet. VLANs werden jetzt nativ unterstützt und auch der Server wird direkt für VLANs konfiguriert. Bei Skriptaufruf wird jetzt direkt geprüft, ob die erforderliche Konfigurationsdatei existiert. Sollte diese nicht existieren, wird diese nun sofort durch ermittelte Daten und einen Fragebogen erstellt. Nach dem erstellen der Konfigurationsdatei wird die Grundkonfiguration Deines Proxmox Home Server durchgeführt. Auf dieser Konfiguration und dem erstellten Konfigurationsskript bauen alle meine anderen Skripte auf.

Aber nun viel Spaß mit deinem neuen Home Server, starten kannst Du mit diesem einfachen Befehl auf der Proxmox Konsole.
```bash
curl -sSL enter.smarthome-iot.net | bash
```

### English
