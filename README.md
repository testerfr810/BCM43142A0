# **BCM43142A0 Bluetooth Activation Scripts**
*Scripts d'activation du Bluetooth sur les cartes **Broadcom BCM43142A0** sous Ubuntu 24.04 (Noble Numbat).*

---

##  **Contexte Technique**
### **Matériel ciblé**
- **Carte Wi-Fi/Bluetooth** : Broadcom **BCM43142A0** (ID PCI: `14e4:4365`, ID USB Bluetooth: `04ca:2006`).
- **Systèmes compatibles** : Ubuntu 24.04 (noyau ≥ 6.8) et distributions dérivées.
- **Pilote Wi-Fi** : `wl` (propriétaire, déjà intégré dans le noyau Ubuntu pour ce matériel).
- **Problème résolu** : Le **firmware Bluetooth manquant** (`BCM43142A0-04ca-2006.hcd`) empêche le module `btusb` de fonctionner.

---

##  **Fichiers disponibles**
   Fichier | Description | Méthode | Dépendances |
 |---------|-------------|---------|-------------|
 | [`BCM43142A0_online.sh`](https://raw.githubusercontent.com/testerfr810/BCM43142A0/main/BCM43142A0_online.sh) | Active le Bluetooth **en ligne** (télécharge le firmware via `wget`). | Requiert une connexion internet. | `wget`, `sudo` |
 | *(Optionnel)* `BCM43142A0_offline.sh` | Active le Bluetooth **hors ligne** (utilise une clé USB avec le firmware pré-téléchargé). | Pour les machines sans accès réseau. | Clé USB avec `BCM43142A0-04ca-2006.hcd` |

---

---

##  **Installation**

---

### ** 1. Méthode en ligne (recommandée)**
**Prérequis** : Connexion internet active.

#### **Commande unique**
```bash
wget -qO- https://raw.githubusercontent.com/testerfr810/BCM43142A0/main/BCM43142A0_online.sh | sudo bash
```


Explications :

wget -qO- : Télécharge le script et l'envoie à stdout.
sudo bash : Exécute le script avec les droits root.
Étapes détaillées

Télécharger le script :


```bash
wget https://raw.githubusercontent.com/testerfr810/BCM43142A0/main/BCM43142A0_online.sh
```


Le rendre exécutable :

```bash
chmod +x BCM43142A0_online.sh
```



L'exécuter :

```bash
sudo ./BCM43142A0_online.sh
```




2. Méthode hors ligne
Prérequis : Une clé USB avec le firmware BCM43142A0-04ca-2006.hcd.
Préparation (depuis un PC avec internet)

Télécharger le firmware :

```bash
wget https://github.com/winterheart/broadcom-bt-firmware/raw/master/brcm/BCM43142A0-04ca-2006.hcd
```


Copier le fichier sur une clé USB (ex: /media/user/USBDRIVE/).
Exécution (sur la machine cible)


Brancher la clé USB et trouver son chemin :

```bash
lsblk | grep -i media
```


Exemple de sortie : /media/user/USBDRIVE.


Télécharger le script hors ligne (si présent) :

```bash
wget https://raw.githubusercontent.com/testerfr810/BCM43142A0/main/BCM43142A0_offline.sh
chmod +x BCM43142A0_offline.sh
```




Modifier le script pour pointer vers le bon chemin de la clé USB :


nano BCM43142A0_offline.sh  # Remplacer CHEMIN_CLE par le chemin réel (ex: /media/user/USBDRIVE)





Exécuter :

```bash
sudo ./BCM43142A0_offline.sh
```




🔍 Vérifications Post-Installation
1. Vérifier le firmware


ls -l /lib/firmware/brcm/BCM43142A0-04ca-2006.hcd



Résultat attendu :

-rw-r--r-- 1 root root 12345 May 16 12:00 /lib/firmware/brcm/BCM43142A0-04ca-2006.hcd

2. Vérifier le statut du Bluetooth

```bash
hciconfig -a
```


Résultat attendu :


    hci0:   Type: Primary  Bus: USB
            BD Address: XX\:XX\:XX\:XX\:XX\:XX  ACL MTU: 1021:8  SCO MTU: 64:1
            UP RUNNING
            RX bytes:1234 acl:0 sco:0 events:45 errors:0
            TX bytes:5678 acl:0 sco:0 commands:45 errors:0



3. Vérifier les modules chargés

```bash
lsmod | grep -E 'btusb|bluetooth|btbcm'
```


Résultat attendu :


    btusb                  65536  0
    bluetooth             819200  15 btrtl,btmtk,btintel,btbcm,bnep,btusb
    btbcm                  16384  1 btusb



4. Vérifier les logs
Les scripts génèrent un log dans :

```bash
cat /var/log/bluetooth_fix_*.log
```



  Dépannage


  
    
      Problème
      Cause probable
      Solution
    
  
  
    
      hci0: DOWN
      Firmware manquant ou incorrect.
      Vérifier /lib/firmware/brcm/BCM43142A0-04ca-2006.hcd.
    
    
      404 Not Found lors du téléchargement
      URL incorrecte ou dépôt privé.
      Vérifier l'URL ou utiliser la méthode hors ligne.
    
    
      Permission denied
      Script non exécutable ou droits insuffisants.
      chmod +x script.sh + sudo.
    
    
      Wi-Fi ne fonctionne pas
      Pilote wl non chargé.
      sudo modprobe wl ou installer broadcom-sta-dkms.
    
    
      Bluetooth toujours inactif
      Module btusb bloqué.
      rfkill unblock bluetooth + redémarrer le service.
    
  



Commandes de diagnostic avancé


Vérifier les erreurs du noyau :

```bash
dmesg | grep -i bluetooth
```


Exemple d'erreur :


    Bluetooth: hci0: BCM: firmware Patch file not found, tried: 'brcm/BCM43142A0-04ca-2006.hcd'





Vérifier le statut du service Bluetooth :

```bash
systemctl status bluetooth
```




Forcer le rechargement du module :

```bash
sudo modprobe -r btusb && sudo modprobe btusb
```




 Détails Techniques
Firmware

Nom : BCM43142A0-04ca-2006.hcd
Source : winterheart/broadcom-bt-firmware
Emplacement : /lib/firmware/brcm/
Permissions : 644 (lecture pour tous, écriture pour root).
Modules Kernel

btusb : Pilote USB pour le Bluetooth.
bluetooth : Pile protocolaire Bluetooth.
btbcm : Support spécifique pour les puces Broadcom.
Pilote Wi-Fi

Module : wl (propriétaire, fourni par Broadcom).
Statut : Déjà intégré dans Ubuntu 24.04 pour le BCM43142.
Vérification :

```bash
lsmod | grep wl
lspci -k | grep -A 3 -i broadcom
```




 Changelog


  
    
      Version
      Date
      Modifications
    
  
  
    
      1.0
      2026-05-16
      Version initiale.
    
  



 Licence MIT
Ce dépôt est fourni sans garantie. Utilisez à vos propres risques.


---


