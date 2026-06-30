#!/bin/bash
# =============================================================
# PROYECTO: Infraestructura Viva - ACME Soluciones Digitales
# LECCIÓN 1: Almacenamiento en Cloud
# SCRIPT 02: Políticas de Ciclo de Vida (Lifecycle Policies)
# Entorno: Floci (emulador AWS local)
# =============================================================

ENDPOINT="http://localhost:4566"

echo "============================================="
echo "  ACME - Configuración de Lifecycle Policies"
echo "============================================="

# -------------------------------------------------------
# POLÍTICA 1: Bucket de archivos estáticos
# Día 30  → transición a S3 Standard-IA (acceso infrecuente)
# Día 90  → transición a S3 Glacier Flexible Retrieval
# Día 365 → expiración (eliminación automática)
# -------------------------------------------------------
echo ""
echo "[1/3] Aplicando política al bucket 'acme-static-files'..."

aws --endpoint-url=$ENDPOINT s3api put-bucket-lifecycle-configuration \
    --bucket acme-static-files \
    --lifecycle-configuration '{
        "Rules": [
            {
                "ID": "acme-static-lifecycle",
                "Status": "Enabled",
                "Filter": { "Prefix": "" },
                "Transitions": [
                    {
                        "Days": 30,
                        "StorageClass": "STANDARD_IA"
                    },
                    {
                        "Days": 90,
                        "StorageClass": "GLACIER"
                    }
                ],
                "Expiration": {
                    "Days": 365
                }
            }
        ]
    }'

echo "    ✔ Política aplicada a 'acme-static-files'"
echo "      Día 30  → Standard-IA"
echo "      Día 90  → Glacier"
echo "      Día 365 → Expiración"

# -------------------------------------------------------
# POLÍTICA 2: Bucket de archivado
# Día 1  → transición directa a Glacier (ya es archivo histórico)
# Día 730 → expiración (2 años de retención)
# -------------------------------------------------------
echo ""
echo "[2/3] Aplicando política al bucket 'acme-archive'..."

aws --endpoint-url=$ENDPOINT s3api put-bucket-lifecycle-configuration \
    --bucket acme-archive \
    --lifecycle-configuration '{
        "Rules": [
            {
                "ID": "acme-archive-lifecycle",
                "Status": "Enabled",
                "Filter": { "Prefix": "" },
                "Transitions": [
                    {
                        "Days": 1,
                        "StorageClass": "GLACIER"
                    }
                ],
                "Expiration": {
                    "Days": 730
                }
            }
        ]
    }'

echo "    ✔ Política aplicada a 'acme-archive'"
echo "      Día 1   → Glacier (inmediato)"
echo "      Día 730 → Expiración (2 años)"

# -------------------------------------------------------
# POLÍTICA 3: Bucket de backups de BD
# Día 7   → transición a Standard-IA
# Día 30  → transición a Glacier
# Día 90  → expiración (retención 3 meses)
# -------------------------------------------------------
echo ""
echo "[3/3] Aplicando política al bucket 'acme-db-backups'..."

aws --endpoint-url=$ENDPOINT s3api put-bucket-lifecycle-configuration \
    --bucket acme-db-backups \
    --lifecycle-configuration '{
        "Rules": [
            {
                "ID": "acme-backup-lifecycle",
                "Status": "Enabled",
                "Filter": { "Prefix": "postgres/" },
                "Transitions": [
                    {
                        "Days": 7,
                        "StorageClass": "STANDARD_IA"
                    },
                    {
                        "Days": 30,
                        "StorageClass": "GLACIER"
                    }
                ],
                "Expiration": {
                    "Days": 90
                }
            }
        ]
    }'

echo "    ✔ Política aplicada a 'acme-db-backups'"
echo "      Día 7  → Standard-IA"
echo "      Día 30 → Glacier"
echo "      Día 90 → Expiración"

# --- Verificación de políticas ---
echo ""
echo "============================================="
echo "  Verificando políticas configuradas:"
echo "============================================="

echo ""
echo "--- acme-static-files ---"
aws --endpoint-url=$ENDPOINT s3api get-bucket-lifecycle-configuration \
    --bucket acme-static-files \
    --query 'Rules[*].{ID:ID,Estado:Status}' \
    --output table

echo ""
echo "--- acme-archive ---"
aws --endpoint-url=$ENDPOINT s3api get-bucket-lifecycle-configuration \
    --bucket acme-archive \
    --query 'Rules[*].{ID:ID,Estado:Status}' \
    --output table

echo ""
echo "--- acme-db-backups ---"
aws --endpoint-url=$ENDPOINT s3api get-bucket-lifecycle-configuration \
    --bucket acme-db-backups \
    --query 'Rules[*].{ID:ID,Estado:Status}' \
    --output table

echo ""
echo "Script 02 completado."
