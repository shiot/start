# [Deutsch](https://github.com/shiot/start#deutsch) - [English](https://github.com/shiot/start#english)
![](https://github.com/shiot/start/blob/master/images/logo.jpg)
## Deutsch
Starte dieses Skript, um die Welt Deines eigenen SmartHome zu betreten und mit der Konfiguration deines Proxmox Home Server zu beginnen.

Bitte benutze dieses Skript nur auf neu installierten Systemen. Wenn Du dieses Skript auf bereits konfigurierten und genutzten Servern einsetzt kann es zu schwerwiegenden Fehlern an deinem Serversystem nutzen. Mir ist es natürlich nicht möglich, dieses Skript auf allen nur erdenklichen Systemen zu testen, aus diesem Grund, kann ich für die richtige Funktion des Skript nicht Garantieren. Die Nutzung dieses Skript geschieht auf eigene Gefahr und Verantwortung. 

Ich habe dieses neue Repository aufgrund eurer Rückmeldungen erstellt und das Skript noch einmal komplett überarbeitet. VLANs werden jetzt nativ unterstützt und auch der Server wird direkt für VLANs konfiguriert. Bei Skriptaufruf wird jetzt direkt geprüft, ob die erforderliche Konfigurationsdatei existiert. Sollte diese nicht existieren, wird diese nun sofort durch ermittelte Daten und einen Fragebogen erstellt. Nach dem erstellen der Konfigurationsdatei wird die Grundkonfiguration Deines Proxmox Home Server durchgeführt. Auf dieser Konfiguration und dem erstellten Konfigurationsskript bauen alle meine anderen Skripte auf.

Aber nun viel Spaß mit deinem neuen Home Server, starten kannst Du mit diesem einfachen Befehl auf der Proxmox Konsole.
```bash
curl -sSL enter.smarthome-iot.net | bash
```
Weitere Informationen findest Du in meinem [Blog](https://smarthome-iot.net)

## English
Launch this script to enter the world of your own SmartHome and start configuring your Proxmox Home Server.

Please use this script only on newly installed systems. If you use this script on already configured and used servers it can cause serious errors on your server system. Of course it is not possible for me to test this script on all possible systems, so I can't guarantee the correct function of this script. The use of this script is at your own risk and responsibility. 

I created this new repository based on your feedback and completely reworked the script again. VLANs are now natively supported and the server is also directly configured for VLANs. When the script is called, it now directly checks if the required configuration file exists. If this does not exist, it is now immediately created by determined data and a questionnaire. After creating the configuration file, the basic configuration of your Proxmox Home Server is performed. All my other scripts are based on this configuration and the created configfile.

But now have fun with your new home server, you can start with this simple command on the Proxmox console.
```bash
curl -sSL enter.smarthome-iot.net | bash
```
You can find more information in my [blog](https://smarthome-iot.net)
