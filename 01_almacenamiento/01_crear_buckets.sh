#!/bin/bash
# =============================================================
# PROYECTO: Infraestructura Viva - ACME Soluciones Digitales
# LECCIÓN 1: Almacenamiento en Cloud
# SCRIPT 01: Creación de Buckets S3
# Entorno: Floci (emulador AWS local)
# =============================================================

# --- Configuración del endpoint Floci ---
ENDPOINT="http://localhost:4566"
REGION="us-east-1"

echo "============================================="
echo "  ACME - Creación de Buckets S3 en Floci"
echo "============================================="

# --- BUCKET 1: Archivos estáticos (uso frecuente) ---
echo ""
echo "[1/3] Creando bucket de archivos estáticos..."
aws --endpoint-url=$ENDPOINT s3 mb s3://acme-static-files \
    --region $REGION

aws --endpoint-url=$ENDPOINT s3api put-bucket-tagging \
    --bucket acme-static-files \
    --tagging 'TagSet=[
        {Key=Proyecto,Value=InfraestructuraViva},
        {Key=Area,Value=Estaticos},
        {Key=Empresa,Value=ACME},
        {Key=Tier,Value=Standard}
    ]'

echo "    ✔ Bucket 'acme-static-files' creado (S3 Standard)"

# --- BUCKET 2: Archivado (datos históricos) ---
echo ""
echo "[2/3] Creando bucket de archivado..."
aws --endpoint-url=$ENDPOINT s3 mb s3://acme-archive \
    --region $REGION

aws --endpoint-url=$ENDPOINT s3api put-bucket-tagging \
    --bucket acme-archive \
    --tagging 'TagSet=[
        {Key=Proyecto,Value=InfraestructuraViva},
        {Key=Area,Value=Archivado},
        {Key=Empresa,Value=ACME},
        {Key=Tier,Value=Glacier}
    ]'

echo "    ✔ Bucket 'acme-archive' creado (destinado a Glacier)"

# --- BUCKET 3: Backups de Base de Datos ---
echo ""
echo "[3/3] Creando bucket de backups de BD..."
aws --endpoint-url=$ENDPOINT s3 mb s3://acme-db-backups \
    --region $REGION

aws --endpoint-url=$ENDPOINT s3api put-bucket-tagging \
    --bucket acme-db-backups \
    --tagging 'TagSet=[
        {Key=Proyecto,Value=InfraestructuraViva},
        {Key=Area,Value=BaseDatos},
        {Key=Empresa,Value=ACME},
        {Key=Tier,Value=Standard-IA}
    ]'

echo "    ✔ Bucket 'acme-db-backups' creado (S3 Standard-IA)"

# --- Verificación final ---
echo ""
echo "============================================="
echo "  Buckets creados exitosamente:"
echo "============================================="
aws --endpoint-url=$ENDPOINT s3 ls

echo ""
echo "Script 01 completado."
