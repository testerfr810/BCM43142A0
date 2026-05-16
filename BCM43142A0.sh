#!/bin/bash
# ============================================================
# SCRIPT POUR Broadcom BCM43142 (Wi-Fi + Bluetooth)
# Ubuntu 24.04 (Noble) - Installation HORS LIGNE
# ============================================================
# LIENS DE TÉLÉCHARGEMENT (depuis un autre PC) :
#
# 1. DKMS :
#    https://archive.ubuntu.com/ubuntu/pool/main/d/dkms/dkms_3.0.11-1ubuntu13_all.deb
#
# 2. Pilote Broadcom STA :
#    https://archive.ubuntu.com/ubuntu/pool/restricted/b/broadcom-sta/broadcom-sta-dkms_6.30.223.271-23ubuntu1.2_all.deb
#
# 3. Firmware Bluetooth :
#    https://github.com/winterheart/broadcom-bt-firmware/raw/master/brcm/BCM43142A0-04ca-2006.hcd
# ============================================================

set -e # Arrête le script en cas d'erreur

# --- CONFIGURATION ---
CHEMIN_CLE="/media/$USER/NOM_DE_LA_CLE" # À adapter selon le nom de ta clé
FICHIER_LOG="$HOME/Bureau/broadcom_install_$(date +%Y%m%d_%H%M%S).log"
FLAG="/tmp/broadcom_install_done" # Flag système (persistant après reboot)

# --- VÉRIFICATIONS PRÉALABLES ---
if [ "$(id -u)" -ne 0 ]; then
    echo "ERREUR : Ce script doit être exécuté en tant que root (sudo)." >&2
    echo "Exemple : sudo $0"
    exit 1
fi

# Vérifie que le dossier de firmware existe
if [ ! -d "/lib/firmware/brcm" ]; then
    mkdir -p /lib/firmware/brcm
fi

# Crée le fichier de log
exec >"$FICHIER_LOG" 2>&1
echo "=== $(date) ==="
echo "Script lancé par : $USER"
echo ""

# --- ÉTAPE 1 : INSTALLATION Wi-Fi ---
if [ ! -f "$FLAG" ]; then
    echo "--- ÉTAPE 1 : INSTALLATION Wi-Fi ---"

    # Nettoyage des anciennes installations
    echo "Nettoyage des anciennes installations..."
    apt purge broadcom-sta-dkms -y || true
    apt autoremove -y || true

    # Vérifie que le chemin de la clé USB existe
    if [ ! -d "$CHEMIN_CLE" ]; then
        echo "ERREUR : Le chemin de la clé USB '$CHEMIN_CLE' n'existe pas." >&2
        echo "Vérifiez que la clé est branchée et que le chemin est correct."
        echo "Astuce : utilisez 'lsblk' ou 'mount | grep media' pour trouver le chemin."
        exit 1
    fi

    # Vérifie que les fichiers .deb sont présents
    for fichier in dkms_3.0.11-1ubuntu13_all.deb broadcom-sta-dkms_6.30.223.271-23ubuntu1.2_all.deb; do
        if [ ! -f "$CHEMIN_CLE/$fichier" ]; then
            echo "ERREUR : Le fichier $fichier est introuvable sur la clé USB." >&2
            exit 1
        fi
    done

    # Installation des paquets depuis la clé USB
    cd "$CHEMIN_CLE" || exit 1
    echo "Installation de DKMS..."
    dpkg -i dkms_3.0.11-1ubuntu13_all.deb
    echo "Installation du pilote Broadcom STA..."
    dpkg -i broadcom-sta-dkms_6.30.223.271-23ubuntu1.2_all.deb

    # Vérification DKMS
    echo "Vérification DKMS :"
    dkms status

    # Crée le flag pour passer à l'étape 2 après redémarrage
    touch "$FLAG"
    echo ""
    echo "=== REDÉMARRAGE NÉCESSAIRE ==="
    echo "Le système va redémarrer dans 5 secondes..."
    echo "Après le redémarrage, relancez ce script pour activer le Bluetooth."
    sleep 5
    reboot
else
    echo "--- ÉTAPE 2 : ACTIVATION BLUETOOTH ---"

    # Vérifie que le flag existe (cohérence)
    if [ ! -f "$FLAG" ]; then
        echo "ERREUR : Flag introuvable, incohérence d'état." >&2
        exit 1
    fi

    # Copie du firmware Bluetooth depuis la clé USB
    if [ ! -f "$CHEMIN_CLE/BCM43142A0-04ca-2006.hcd" ]; then
        echo "ERREUR : Le fichier BCM43142A0-04ca-2006.hcd n'est pas trouvé sur la clé USB." >&2
        exit 1
    fi

    echo "Copie du firmware Bluetooth..."
    cp "$CHEMIN_CLE/BCM43142A0-04ca-2006.hcd" /lib/firmware/brcm/
    chmod 644 /lib/firmware/brcm/BCM43142A0-04ca-2006.hcd

    # Rechargement des modules et services
    echo "Rechargement des modules et services..."
    modprobe -r btusb 2>/dev/null || true
    modprobe btusb reset=1
    systemctl restart bluetooth
    rfkill unblock bluetooth

    # Nettoyage du flag
    rm -f "$FLAG"

    echo ""
    echo "=== RÉSULTAT FINAL ==="
    rfkill list
    echo ""
    echo "=== TERMINÉ : Wi-Fi et Bluetooth doivent fonctionner ==="
    echo "Vérifiez avec :"
    echo "  - lspci | grep -i broadcom (pour le Wi-Fi)"
    echo "  - hciconfig -a (pour le Bluetooth)"
fi
