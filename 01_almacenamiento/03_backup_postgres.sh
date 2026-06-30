#!/bin/bash
# =============================================================
# PROYECTO: Infraestructura Viva - ACME Soluciones Digitales
# LECCIÓN 1: Almacenamiento en Cloud
# SCRIPT 03: Backup Automático PostgreSQL → S3
# Entorno: Floci (emulador AWS local)
# =============================================================

ENDPOINT="http://localhost:4566"
BUCKET="acme-db-backups"
PREFIX="postgres"

# --- Configuración de la base de datos (acme-postgres en Floci) ---
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="acme"
DB_USER="postgres"

# --- Configuración de fechas y nombres ---
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FECHA=$(date +"%Y-%m-%d")
BACKUP_FILE="acme_backup_${TIMESTAMP}.sql"
BACKUP_PATH="/tmp/${BACKUP_FILE}"

echo "============================================="
echo "  ACME - Backup PostgreSQL → S3"
echo "  Fecha: $FECHA"
echo "============================================="

# -------------------------------------------------------
# PASO 1: Generar dump de la base de datos
# -------------------------------------------------------
echo ""
echo "[1/4] Generando dump de la base 'acme'..."

PGPASSWORD=acme_password pg_dump \
    -h $DB_HOST \
    -p $DB_PORT \
    -U $DB_USER \
    -d $DB_NAME \
    --format=plain \
    --clean \
    --if-exists \
    -f $BACKUP_PATH

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -sh $BACKUP_PATH | cut -f1)
    echo "    ✔ Dump generado: $BACKUP_FILE ($BACKUP_SIZE)"
else
    echo "    ✘ Error al generar el dump. Abortando."
    exit 1
fi

# -------------------------------------------------------
# PASO 2: Comprimir el backup
# -------------------------------------------------------
echo ""
echo "[2/4] Comprimiendo backup..."

gzip $BACKUP_PATH
BACKUP_GZ="${BACKUP_PATH}.gz"
BACKUP_FILE_GZ="${BACKUP_FILE}.gz"

if [ $? -eq 0 ]; then
    COMPRESSED_SIZE=$(du -sh $BACKUP_GZ | cut -f1)
    echo "    ✔ Backup comprimido: $BACKUP_FILE_GZ ($COMPRESSED_SIZE)"
else
    echo "    ✘ Error al comprimir. Abortando."
    exit 1
fi

# -------------------------------------------------------
# PASO 3: Subir a S3 (bucket acme-db-backups)
# -------------------------------------------------------
echo ""
echo "[3/4] Subiendo backup al bucket '$BUCKET'..."

aws --endpoint-url=$ENDPOINT s3 cp \
    $BACKUP_GZ \
    s3://$BUCKET/$PREFIX/$FECHA/$BACKUP_FILE_GZ \
    --storage-class STANDARD \
    --metadata "fecha=$FECHA,origen=acme-postgres,base=$DB_NAME"

if [ $? -eq 0 ]; then
    echo "    ✔ Backup subido a: s3://$BUCKET/$PREFIX/$FECHA/$BACKUP_FILE_GZ"
else
    echo "    ✘ Error al subir el backup a S3."
    rm -f $BACKUP_GZ
    exit 1
fi

# -------------------------------------------------------
# PASO 4: Limpieza y verificación
# -------------------------------------------------------
echo ""
echo "[4/4] Limpiando archivos temporales y verificando..."

rm -f $BACKUP_GZ
echo "    ✔ Archivo temporal eliminado"

echo ""
echo "  Backups disponibles en S3:"
aws --endpoint-url=$ENDPOINT s3 ls \
    s3://$BUCKET/$PREFIX/ \
    --recursive \
    --human-readable

echo ""
echo "============================================="
echo "  Backup completado exitosamente."
echo "  Archivo: $BACKUP_FILE_GZ"
echo "  Destino: s3://$BUCKET/$PREFIX/$FECHA/"
echo "  El ciclo de vida moverá este backup:"
echo "    → Standard-IA en 7 días"
echo "    → Glacier en 30 días"
echo "    → Eliminación en 90 días"
echo "============================================="

# -------------------------------------------------------
# NOTA: Para ejecutar automáticamente este script,
# agregar al cron con: crontab -e
# Ejemplo - ejecutar todos los días a las 02:00 AM:
# 0 2 * * * /ruta/al/script/03_backup_postgres.sh >> /var/log/acme_backup.log 2>&1
# -------------------------------------------------------
