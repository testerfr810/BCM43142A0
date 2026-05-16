#!/bin/bash
# ============================================================
# SCRIPT POUR ACTIVER LE BLUETOOTH BCM43142A0 (ASUS X555LD)
# Ubuntu 24.04 - Installation en ligne
# Auteur : dark dark
# Date : 2026-05-16
# ============================================================

set -e

# --- Configuration ---
LOG_FILE="/var/log/bluetooth_fix_$(date +%Y%m%d_%H%M%S).log"
FIRMWARE_URL="https://github.com/winterheart/broadcom-bt-firmware/raw/master/brcm/BCM43142A0-04ca-2006.hcd"
FIRMWARE_PATH="/lib/firmware/brcm/BCM43142A0-04ca-2006.hcd"

# --- Initialisation du log ---
{
    echo "=========================================="
    echo "DEBUT DU SCRIPT - $(date)"
    echo "Utilisateur : $USER"
    echo "Hostname : $(hostname)"
    echo "=========================================="
    echo ""
} | tee -a "$LOG_FILE"

# --- Vérification des droits root ---
if [ "$(id -u)" -ne 0 ]; then
    echo "ERREUR : Ce script doit etre execute en tant que root (sudo)." >&2
    echo "Commande recommandee : sudo $0"
    exit 1
fi

# --- Installation des dependances ---
echo "[ETAPE 1/4] Installation des dependances..."
{
    apt update -y
    apt install -y wget
} >>"$LOG_FILE" 2>&1
echo "Dependances installees ou deja presentes."
echo ""

# --- Telechargement du firmware ---
echo "[ETAPE 2/4] Telechargement du firmware Bluetooth..."
if [ ! -d "/lib/firmware/brcm" ]; then
    mkdir -p /lib/firmware/brcm
    echo "Dossier /lib/firmware/brcm cree."
fi

wget -O "$FIRMWARE_PATH" "$FIRMWARE_URL" >>"$LOG_FILE" 2>&1
if [ ! -f "$FIRMWARE_PATH" ]; then
    echo "ERREUR : Echec du telechargement du firmware." >&2
    exit 1
fi
echo "Firmware telecharge : $FIRMWARE_PATH"
echo ""

# --- Configuration des permissions ---
echo "[ETAPE 3/4] Application des permissions..."
chmod 644 "$FIRMWARE_PATH"
echo "Permissions appliquees (644) sur $FIRMWARE_PATH"
echo ""

# --- Rechargement du module Bluetooth ---
echo "[ETAPE 4/4] Rechargement du module Bluetooth..."
{
    modprobe -r btusb 2>/dev/null || true
    modprobe btusb
    systemctl restart bluetooth
    rfkill unblock bluetooth
} >>"$LOG_FILE" 2>&1
echo "Module btusb recharge et service Bluetooth redemarre."
echo ""

# --- Verification finale ---
{
    echo ""
    echo "=========================================="
    echo "VERIFICATION FINALE"
    echo "=========================================="
    echo ""

    echo "1. Fichier firmware present ?"
    if [ -f "$FIRMWARE_PATH" ]; then
        ls -l "$FIRMWARE_PATH"
        echo "Statut : OK"
    else
        echo "Statut : ERREUR - Fichier introuvable"
    fi
    echo ""

    echo "2. Statut du Bluetooth :"
    hciconfig -a 2>&1
    echo ""

    echo "3. Modules Bluetooth charges :"
    lsmod | grep -E 'btusb|bluetooth|btbcm'
    echo ""

    echo "4. Service Bluetooth :"
    systemctl status bluetooth --no-pager
    echo ""

    echo "=========================================="
    echo "FIN DU SCRIPT - $(date)"
    echo "Fichier de log : $LOG_FILE"
    echo "=========================================="
} | tee -a "$LOG_FILE"
