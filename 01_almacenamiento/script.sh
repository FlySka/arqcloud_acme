#!/bin/bash
# =============================================================
# PROYECTO: Infraestructura Viva - ACME Soluciones Digitales
# LECCIÓN 1: Almacenamiento en Cloud
# SCRIPT MAESTRO: Ejecuta toda la configuración en orden
# Entorno: Floci (emulador AWS local)
# =============================================================

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Dar permisos de ejecución
chmod +x $SCRIPTS_DIR/01_crear_buckets.sh
chmod +x $SCRIPTS_DIR/02_lifecycle_policies.sh
chmod +x $SCRIPTS_DIR/03_backup_postgres.sh

# --- PASO 1: Crear Buckets ---
echo ">>> PASO 1: Creando buckets S3..."
bash $SCRIPTS_DIR/01_crear_buckets.sh
if [ $? -ne 0 ]; then
    echo "Error en la creación de buckets. Abortando."
    exit 1
fi

echo ""
echo "--- Pausa 2 segundos ---"
sleep 2

# --- PASO 2: Lifecycle Policies ---
echo ""
echo ">>> PASO 2: Configurando políticas de ciclo de vida..."
bash $SCRIPTS_DIR/02_lifecycle_policies.sh
if [ $? -ne 0 ]; then
    echo "Error en las políticas de ciclo de vida. Abortando."
    exit 1
fi

echo ""
echo "--- Pausa 2 segundos ---"
sleep 2

# --- PASO 3: Primer Backup ---
echo ""
echo ">>> PASO 3: Ejecutando primer backup de la base de datos..."
bash $SCRIPTS_DIR/03_backup_postgres.sh
if [ $? -ne 0 ]; then
    echo "Advertencia: El backup falló (puede ser porque pg_dump no está disponible en Floci)."
    echo "El script se puede ejecutar manualmente cuando la BD esté accesible."
fi

echo ""
echo "##############################################"
echo "#  Lección 1 completada.                    #"
echo "#  Resumen de recursos creados:             #"
echo "#  - acme-static-files  → S3 Standard       #"
echo "#  - acme-archive       → S3 → Glacier      #"
echo "#  - acme-db-backups    → Backup PostgreSQL  #"
echo "#  - 3 lifecycle policies configuradas      #"
echo "##############################################"
echo ""
