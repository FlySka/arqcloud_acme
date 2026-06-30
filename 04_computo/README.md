# Lección 4 — Servicios de Cómputo AWS

## Servicios desplegados

| # | Servicio | Tipo | Free Tier |
|---|----------|------|-----------|
| 1 | EC2 + Auto Scaling Group | IaaS | ✅ t2.micro 750h/mes |
| 2 | ECS Fargate | CaaS | ⚠️ AWS Academy |
| 3 | Lambda + API Gateway | FaaS/Serverless | ✅ 1M invoc./mes |

---

## Estructura del proyecto

```
leccion4-compute/
├── main.tf                    # Orquestación de los 3 módulos
├── variables.tf
├── outputs.tf
├── load_test.sh               # Script de pruebas de escalabilidad
├── artillery.yml              # Config de carga avanzada (Artillery)
└── modules/
    ├── ec2-asg/               # Servicio 1: EC2 + Auto Scaling
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── ecs-fargate/           # Servicio 2: ECS Fargate
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── lambda/                # Servicio 3: Lambda + API Gateway
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── lambda_function.py
```

---

## Despliegue paso a paso

### Prerrequisitos
- AWS CLI configurado (`aws configure`)
- Terraform >= 1.6 instalado
- Cuenta AWS con Free Tier o AWS Academy activo

### 1. Inicializar y desplegar

```bash
cd leccion4-compute

# Inicializar providers
terraform init

# Verificar el plan
terraform plan -var="project_name=leccion4" -var="environment=dev"

# Desplegar (aprox. 5-8 minutos)
terraform apply -var="project_name=leccion4" -var="environment=dev"
```

### 2. Obtener las URLs

```bash
terraform output
# Verás:
#   ec2_alb_dns    = "http://leccion4-ec2-alb-xxx.us-east-1.elb.amazonaws.com"
#   ecs_alb_dns    = "http://leccion4-ecs-alb-xxx.us-east-1.elb.amazonaws.com"
#   lambda_api_url = "https://xxx.execute-api.us-east-1.amazonaws.com/demo"
```

### 3. Verificar que funcionan

```bash
# EC2
curl http://TU-EC2-ALB/

# ECS
curl http://TU-ECS-ALB/

# Lambda (con parámetro de cálculo)
curl "https://TU-LAMBDA-URL/demo?n=1000"
```

---

## Pruebas de escalabilidad

### Método 1 — Script incluido (recomendado)

```bash
chmod +x load_test.sh

./load_test.sh \
  "http://TU-EC2-ALB" \
  "http://TU-ECS-ALB" \
  "https://TU-LAMBDA-URL/demo" \
  "leccion4-ec2-asg"
```

El script genera un reporte `escalabilidad_YYYYMMDD_HHMMSS.txt`

### Método 2 — Apache Bench (manual)

```bash
# Instalar: sudo apt install apache2-utils

# EC2: 3000 peticiones, 50 concurrentes
ab -n 3000 -c 50 http://TU-EC2-ALB/

# Lambda: 500 peticiones, 100 concurrentes
ab -n 500 -c 100 https://TU-LAMBDA-URL/demo
```

### Método 3 — Artillery (carga realista)

```bash
# Instalar: npm install -g artillery
# Editar artillery.yml → reemplazar target con tu URL

artillery run artillery.yml --target http://TU-EC2-ALB
```

---

## Métricas requeridas por la lección

### Métrica 1 — Instancia o función desplegada ✅

Verificar con:
```bash
# EC2
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=leccion4" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]' \
  --output table

# ECS
aws ecs describe-services \
  --cluster leccion4-cluster \
  --services leccion4-fargate-service \
  --query 'services[0].{Deseadas:desiredCount,Corriendo:runningCount}' \
  --output json

# Lambda
aws lambda get-function --function-name leccion4-demo \
  --query 'Configuration.{Estado:State,Memoria:MemorySize,Runtime:Runtime}'
```

### Métrica 2 — Hasta 3 servicios utilizados ✅

| Servicio | Estado esperado |
|----------|----------------|
| EC2 ASG  | 1-3 instancias t2.micro corriendo |
| ECS Fargate | 1-6 tareas según carga |
| Lambda | Disponible, escala a N ejecuciones concurrentes |

### Métrica 3 — Prueba de escalabilidad documentada ✅

**EC2 Auto Scaling — evidencia esperada:**
```
Antes de la carga:
  DesiredCapacity: 1
  Instancias: [i-0abc123...]

Después (CPU > 60% durante 2 min):
  DesiredCapacity: 2 o 3
  Instancias: [i-0abc123..., i-0def456...]
```

**ECS Fargate — evidencia esperada:**
```
Antes:  runningCount: 1
Después (CPU tareas > 50%): runningCount: 2-4
```

**Lambda — evidencia esperada:**
```
ConcurrentExecutions máximo: 50-100
(Lambda escaló automáticamente sin configuración)
```

---

## Dónde ver los resultados en la consola AWS

| Servicio | Consola AWS |
|----------|------------|
| EC2 ASG | EC2 → Auto Scaling Groups → leccion4-ec2-asg → Activity |
| ECS | ECS → Clusters → leccion4-cluster → Services → Tasks |
| Lambda | Lambda → leccion4-demo → Monitor → Invocaciones |
| Alarmas | CloudWatch → Alarms |
| Logs | CloudWatch → Log Groups |

---

## Destruir recursos (evitar costos)

```bash
terraform destroy -var="project_name=leccion4" -var="environment=dev"
```

> ⚠️ Ejecutar siempre al terminar la práctica para no consumir créditos de AWS Academy.
