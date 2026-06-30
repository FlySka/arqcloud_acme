# 🗄️ Lección 3 – Bases de Datos NoSQL con DynamoDB

> **Curso:** Arquitectura Cloud  
> **Herramientas:** AWS CLI · Floci (Local Cloud) · Docker Desktop · Visual Studio Code  
> **Entorno:** Windows – PowerShell

---

## 📋 Descripción

Implementación de una base de datos NoSQL usando **Amazon DynamoDB** emulado localmente con **Floci**, para gestionar un sistema de tickets de soporte técnico. La tabla almacena datos semiestructurados con 3 índices secundarios globales (GSI) que permiten consultas rápidas por múltiples dimensiones.

---

## 🛠️ Requisitos previos

| Herramienta | Instalación |
|-------------|-------------|
| Docker Desktop | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop) |
| Floci CLI | `curl -fsSL https://floci.io/install.sh \| sh` |
| AWS CLI v2 | [aws.amazon.com/cli](https://aws.amazon.com/cli) |
| Visual Studio Code | [code.visualstudio.com](https://code.visualstudio.com) |

---

## 🚀 Inicio rápido

### 1. Iniciar Floci

```powershell
floci start
```

Floci estará disponible en:
- **API:** `http://localhost:4566`
- **Consola UI:** `http://localhost:4500/console/aws`

### 2. Configurar AWS CLI

```powershell
aws configure
```

Ingresar estos valores:
```
AWS Access Key ID:     test
AWS Secret Access Key: test
Default region name:   us-east-1
Default output format: json
```

### 3. Crear el archivo de índices

```powershell
[System.IO.File]::WriteAllText("$PWD\gsi.json", '[{"IndexName":"estado-index","KeySchema":[{"AttributeName":"estado","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}},{"IndexName":"tecnico-index","KeySchema":[{"AttributeName":"tecnico","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}},{"IndexName":"prioridad-index","KeySchema":[{"AttributeName":"prioridad","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}}]')
```

### 4. Crear la tabla

```powershell
aws dynamodb create-table `
  --table-name TicketsSoporte `
  --attribute-definitions `
    AttributeName=ticketId,AttributeType=S `
    AttributeName=estado,AttributeType=S `
    AttributeName=tecnico,AttributeType=S `
    AttributeName=prioridad,AttributeType=S `
  --key-schema AttributeName=ticketId,KeyType=HASH `
  --billing-mode PAY_PER_REQUEST `
  --global-secondary-indexes file://gsi.json `
  --endpoint-url http://localhost:4566
```

### 5. Insertar datos de ejemplo

Crear los archivos JSON:

```powershell
[System.IO.File]::WriteAllText("$PWD\tk1.json", '{"ticketId":{"S":"TK-2026-0001"},"clienteId":{"S":"CL-001"},"departamento":{"S":"Ventas"},"categoria":{"S":"Software"},"prioridad":{"S":"Alta"},"estado":{"S":"Abierto"},"tecnico":{"S":"Carlos Perez"},"fechaCreacion":{"S":"2026-06-28"},"descripcion":{"S":"Error al iniciar sesion en el CRM"}}')

[System.IO.File]::WriteAllText("$PWD\tk2.json", '{"ticketId":{"S":"TK-2026-0002"},"clienteId":{"S":"CL-002"},"departamento":{"S":"Finanzas"},"categoria":{"S":"Hardware"},"prioridad":{"S":"Media"},"estado":{"S":"En proceso"},"tecnico":{"S":"Ana Soto"},"fechaCreacion":{"S":"2026-06-27"},"descripcion":{"S":"Impresora de facturas no responde"}}')

[System.IO.File]::WriteAllText("$PWD\tk3.json", '{"ticketId":{"S":"TK-2026-0003"},"clienteId":{"S":"CL-003"},"departamento":{"S":"Soporte"},"categoria":{"S":"Red"},"prioridad":{"S":"Baja"},"estado":{"S":"Cerrado"},"tecnico":{"S":"Luis Rojas"},"fechaCreacion":{"S":"2026-06-25"},"descripcion":{"S":"Sin conexion a internet en sala de reuniones"}}')

[System.IO.File]::WriteAllText("$PWD\tk4.json", '{"ticketId":{"S":"TK-2026-0004"},"clienteId":{"S":"CL-001"},"departamento":{"S":"Ventas"},"categoria":{"S":"Software"},"prioridad":{"S":"Critica"},"estado":{"S":"Abierto"},"tecnico":{"S":"Carlos Perez"},"fechaCreacion":{"S":"2026-06-28"},"descripcion":{"S":"Sistema de ventas caido durante presentacion"}}')

[System.IO.File]::WriteAllText("$PWD\tk5.json", '{"ticketId":{"S":"TK-2026-0005"},"clienteId":{"S":"CL-004"},"departamento":{"S":"Finanzas"},"categoria":{"S":"Software"},"prioridad":{"S":"Alta"},"estado":{"S":"Abierto"},"tecnico":{"S":"Maria Lopez"},"fechaCreacion":{"S":"2026-06-28"},"descripcion":{"S":"No se puede generar reporte mensual"}}')
```

Insertar los 5 tickets:

```powershell
aws dynamodb put-item --table-name TicketsSoporte --item file://tk1.json --endpoint-url http://localhost:4566
aws dynamodb put-item --table-name TicketsSoporte --item file://tk2.json --endpoint-url http://localhost:4566
aws dynamodb put-item --table-name TicketsSoporte --item file://tk3.json --endpoint-url http://localhost:4566
aws dynamodb put-item --table-name TicketsSoporte --item file://tk4.json --endpoint-url http://localhost:4566
aws dynamodb put-item --table-name TicketsSoporte --item file://tk5.json --endpoint-url http://localhost:4566
```

---

## 🗂️ Estructura de la tabla

**Nombre:** `TicketsSoporte`  
**Clave primaria:** `ticketId` (String)  
**Formato de ID:** `TK-AAAA-NNNN` (ej: `TK-2026-0001`)

| Campo | Tipo | Ejemplo |
|-------|------|---------|
| ticketId | String | TK-2026-0001 |
| clienteId | String | CL-001 |
| departamento | String | Ventas |
| categoria | String | Software |
| prioridad | String | Alta |
| estado | String | Abierto |
| tecnico | String | Carlos Pérez |
| fechaCreacion | String | 2026-06-28 |
| descripcion | String | Error al iniciar sesión |


---

## 🔍 Índices secundarios globales (GSI)

| Índice | Atributo | Caso de uso |
|--------|----------|-------------|
| `estado-index` | estado | Ver todos los tickets abiertos / cerrados |
| `tecnico-index` | tecnico | Consultar tickets por técnico asignado |
| `prioridad-index` | prioridad | Filtrar tickets críticos o urgentes |

---

## 📡 Consultas de ejemplo

Crear archivos de valores:

```powershell
[System.IO.File]::WriteAllText("$PWD\q-estado.json",   '{":e":{"S":"Abierto"}}')
[System.IO.File]::WriteAllText("$PWD\q-tecnico.json",  '{":t":{"S":"Carlos Perez"}}')
[System.IO.File]::WriteAllText("$PWD\q-prioridad.json",'{":p":{"S":"Critica"}}')
```

**Ver todos los tickets (Scan):**
```powershell
aws dynamodb scan --table-name TicketsSoporte --endpoint-url http://localhost:4566
```

**Tickets Abiertos (`estado-index`):**
```powershell
aws dynamodb query --table-name TicketsSoporte --index-name estado-index --keycondition-expression "estado = :e" --expression-attribute-values file://qestado.json --endpoint-url http://localhost:4566

```

**Tickets de Carlos Pérez (`tecnico-index`):**
```powershell
aws dynamodb query --table-name TicketsSoporte --index-name tecnico-index --
key-condition-expression "tecnico = :t" --expression-attribute-values file://qtecnico.json --endpoint-url http://localhost:4566
```

**Tickets Críticos (`prioridad-index`):**
```powershell
aws dynamodb query --table-name TicketsSoporte --index-name prioridad-index --
key-condition-expression "prioridad = :p" --expression-attribute-values
file://q-prioridad.json --endpoint-url http://localhost:4566
```

---

## 📁 Archivos del proyecto

```
proyecto/
├── comandos.txt
├── README.md                        ← Este archivo
├── gsi.json                         ← Definición de los 3 índices GSI
├── tk1.json – tk5.json              ← Datos de los 5 tickets
├── q-estado.json                    ← Valor para consulta por estado
├── q-tecnico.json                   ← Valor para consulta por técnico
└── q-prioridad.json                 ← Valor para consulta por prioridad

```

---

## ✅ Métricas cumplidas

- [x] 1 tabla NoSQL creada (`TicketsSoporte`)
- [x] 3 índices secundarios configurados (`estado-index`, `tecnico-index`, `prioridad-index`)
- [x] 1 integración funcional con aplicación (app HTML + AWS SDK v3)

---

## 🛑 Detener Floci

```powershell
floci stop
```
