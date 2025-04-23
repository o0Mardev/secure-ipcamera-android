#!/bin/sh

echo "📥 Scarico l'ultima versione di Easy-RSA..."

cd ~ || exit

# Prendi il link all'ultima versione .tgz (escludendo .sig)
LATEST=$(curl -s https://api.github.com/repos/OpenVPN/easy-rsa/releases/latest \
  | grep "browser_download_url" \
  | grep -v ".sig" \
  | grep ".tgz" \
  | cut -d '"' -f 4)

if [ -z "$LATEST" ]; then
  echo "❌ Impossibile trovare la release. Controlla la connessione o il link GitHub."
  exit 1
fi

# Scarica l'archivio
curl -LO "$LATEST"

# Estrai l'archivio e cattura il nome della cartella estratta
ARCHIVE_NAME=$(basename "$LATEST")
DIR_NAME=$(tar -tzf "$ARCHIVE_NAME" | head -1 | cut -f1 -d"/")

tar -xzf "$ARCHIVE_NAME"

# Rinomina la directory in "easy-rsa"
if [ -d "$DIR_NAME" ]; then
  mv "$DIR_NAME" easy-rsa
else
  echo "❌ Errore: la directory estratta non esiste"
  exit 1
fi

cd easy-rsa || exit
chmod +x easyrsa

echo "✅ Easy-RSA installato correttamente nella directory ~/easy-rsa"
echo "ℹ️ Ora puoi usare './easyrsa' per inizializzare la PKI e generare i certificati"
