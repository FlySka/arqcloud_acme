#!/usr/bin/env bash
# =============================================================
#  Lección 4 — Script de pruebas de escalabilidad
#  Requiere: ab (apache2-utils), curl, aws-cli, jq
#  Uso: ./load_test.sh <EC2_ALB_URL> <ECS_ALB_URL> <LAMBDA_URL>
# =============================================================
set -euo pipefail

EC2_URL="${1:-http://REEMPLAZA-CON-TU-EC2-ALB}"
ECS_URL="${2:-http://REEMPLAZA-CON-TU-ECS-ALB}"
LAMBDA_URL="${3:-https://REEMPLAZA-CON-TU-LAMBDA-URL/demo}"
ASG_NAME="${4:-leccion4-ec2-asg}"

REPORT_FILE="escalabilidad_$(date +%Y%m%d_%H%M%S).txt"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$REPORT_FILE"; }

# ── Verificar dependencias ────────────────────────────────────────
check_deps() {
  for cmd in ab curl aws jq; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "ERROR: '$cmd' no está instalado."
      echo "  Ubuntu/Debian: sudo apt install apache2-utils curl awscli jq"
      echo "  macOS:         brew install httpd curl awscli jq"
      exit 1
    fi
  done
}

# ── Prueba 1: EC2 Auto Scaling ────────────────────────────────────
test_ec2() {
  log "═══ PRUEBA 1: EC2 Auto Scaling ═══"
  log "Target URL: $EC2_URL"
  log "Verificando que el ALB responde..."
  curl -sf "$EC2_URL" -o /dev/null && log "✓ EC2 ALB OK" || { log "✗ EC2 no responde. Revisa el despliegue."; return 1; }

  log "Instancias antes de la carga:"
  aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$ASG_NAME" \
    --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
    --output text 2>/dev/null | tee -a "$REPORT_FILE" || log "(aws cli no configurado — revisa manualmente en la consola)"

  log "Ejecutando carga: 3000 peticiones, concurrencia 50..."
  ab -n 3000 -c 50 -q "$EC2_URL/" 2>&1 | tee -a "$REPORT_FILE"

  log "Esperando 90s para que CloudWatch detecte la CPU alta..."
  sleep 90

  log "Instancias DESPUÉS de la carga (esperar hasta 3 min para escalado):"
  aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$ASG_NAME" \
    --query 'AutoScalingGroups[0].{Deseadas:DesiredCapacity,Min:MinSize,Max:MaxSize,Instancias:Instances[*].InstanceId}' \
    --output json 2>/dev/null | tee -a "$REPORT_FILE" || log "(revisa en la consola AWS > EC2 > Auto Scaling Groups)"
  log "✓ Prueba EC2 completada"
}

# ── Prueba 2: ECS Fargate ─────────────────────────────────────────
test_ecs() {
  log ""
  log "═══ PRUEBA 2: ECS Fargate ═══"
  log "Target URL: $ECS_URL"
  curl -sf "$ECS_URL" -o /dev/null && log "✓ ECS ALB OK" || { log "✗ ECS no responde."; return 1; }

  log "Tareas activas antes:"
  aws ecs describe-services \
    --cluster "leccion4-cluster" \
    --services "leccion4-fargate-service" \
    --query 'services[0].{Deseadas:desiredCount,Corriendo:runningCount,Pendientes:pendingCount}' \
    --output json 2>/dev/null | tee -a "$REPORT_FILE" || log "(revisa en la consola AWS > ECS)"

  log "Ejecutando carga: 2000 peticiones, concurrencia 30..."
  ab -n 2000 -c 30 -q "$ECS_URL/" 2>&1 | tee -a "$REPORT_FILE"

  log "Tareas activas después (puede tomar 1-2 min escalar):"
  sleep 60
  aws ecs describe-services \
    --cluster "leccion4-cluster" \
    --services "leccion4-fargate-service" \
    --query 'services[0].{Deseadas:desiredCount,Corriendo:runningCount}' \
    --output json 2>/dev/null | tee -a "$REPORT_FILE"
  log "✓ Prueba ECS completada"
}

# ── Prueba 3: Lambda concurrencia ─────────────────────────────────
test_lambda() {
  log ""
  log "═══ PRUEBA 3: Lambda — concurrencia automática ═══"
  log "Target URL: $LAMBDA_URL"

  log "Invocación simple de prueba:"
  curl -sf "$LAMBDA_URL?n=1000" | jq '.calculo' 2>/dev/null | tee -a "$REPORT_FILE" \
    || log "(instala jq o revisa la URL)"

  log "Ejecutando 500 peticiones concurrentes (Lambda escala automáticamente)..."
  ab -n 500 -c 100 -q "$LAMBDA_URL" 2>&1 | tee -a "$REPORT_FILE"

  log "Métricas Lambda post-carga:"
  END=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  START=$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
       || date -u -v-5M +%Y-%m-%dT%H:%M:%SZ)  # macOS compatible

  aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name ConcurrentExecutions \
    --dimensions Name=FunctionName,Value="leccion4-demo" \
    --start-time "$START" \
    --end-time "$END" \
    --period 60 \
    --statistics Maximum \
    --query 'sort_by(Datapoints, &Timestamp)[*].{Tiempo:Timestamp,ConcMax:Maximum}' \
    --output table 2>/dev/null | tee -a "$REPORT_FILE" \
    || log "(revisa en la consola AWS > Lambda > Monitor)"

  log "✓ Prueba Lambda completada"
}

# ── Resumen final ─────────────────────────────────────────────────
summary() {
  log ""
  log "═══ RESUMEN — Lección 4 ═══"
  log "Reporte guardado en: $REPORT_FILE"
  log ""
  log "MÉTRICAS REQUERIDAS:"
  log "  ✓ Servicio 1 EC2:     verificar instancias escaladas en Auto Scaling"
  log "  ✓ Servicio 2 ECS:     verificar tareas Fargate añadidas"
  log "  ✓ Servicio 3 Lambda:  verificar ConcurrentExecutions en CloudWatch"
  log ""
  log "DÓNDE VER LOS RESULTADOS:"
  log "  EC2 ASG:  AWS Console > EC2 > Auto Scaling Groups > $ASG_NAME"
  log "  ECS:      AWS Console > ECS > Clusters > leccion4-cluster"
  log "  Lambda:   AWS Console > Lambda > leccion4-demo > Monitor"
  log "  Alarmas:  AWS Console > CloudWatch > Alarms"
}

# ── Main ──────────────────────────────────────────────────────────
main() {
  log "Iniciando pruebas de escalabilidad — Lección 4"
  log "Fecha: $(date)"
  log ""
  check_deps
  test_ec2
  test_ecs
  test_lambda
  summary
}

main "$@"
