# 02 - Bases de datos relacionales - RDS

Paso a paso usado para simular Amazon RDS con PostgreSQL en Floci.

## Pasos

1. Crear la instancia PostgreSQL ([01_create_rds_pg.sh](./01_create_rds_pg.sh)):

```bash
aws rds create-db-instance \
  --db-instance-identifier acme-postgres \
  --engine postgres \
  --engine-version 16 \
  --db-instance-class db.t3.micro \
  --allocated-storage 20 \
  --master-username acmeadmin \
  --master-user-password "AcmePass123!" \
  --db-name acme \
  --backup-retention-period 7 \
  --multi-az \
  --no-publicly-accessible
```

2. Revisar estado, motor, backup, Multi-AZ y endpoint ([02_check_bd_state.sh](./02_check_bd_state.sh)):

```bash
aws rds describe-db-instances \
  --query "DBInstances[?DBInstanceIdentifier=='acme-postgres']|[0].{ID:DBInstanceIdentifier,Estado:DBInstanceStatus,Motor:Engine,MultiAZ:MultiAZ,Backup:BackupRetentionPeriod,Endpoint:Endpoint.Address,Puerto:Endpoint.Port}" \
  --output table
```

3. Cargar host y puerto ([03_get_endpoint_and_ports.sh](./03_get_endpoint_and_ports.sh)):

```bash
export DB_HOST=localhost

export DB_PORT=$(aws rds describe-db-instances \
  --query "DBInstances[?DBInstanceIdentifier=='acme-postgres']|[0].Endpoint.Port" \
  --output text)

echo $DB_HOST
echo $DB_PORT
```

Si se ejecuta el archivo, usar `source ./03_get_endpoint_and_ports.sh`, no `bash`, para conservar `DB_HOST` y `DB_PORT` en la misma terminal.

4. Validar conexion con `psql` ([04_conect_bd.sh](./04_conect_bd.sh)):

```bash
psql "host=$DB_HOST port=$DB_PORT dbname=acme user=acmeadmin password=AcmePass123!"
```

5. Crear tablas e insertar datos ([05_create_tables.sh](./05_create_tables.sh)):

```sql
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    area VARCHAR(50) NOT NULL
);

CREATE TABLE tickets (
    id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES clientes(id),
    descripcion TEXT NOT NULL,
    estado VARCHAR(30) NOT NULL,
    prioridad VARCHAR(20) NOT NULL,
    fecha_creacion DATE NOT NULL
);

INSERT INTO clientes (nombre, area) VALUES
('Ventas ACME', 'Ventas'),
('Soporte ACME', 'Soporte'),
('Finanzas ACME', 'Finanzas');

INSERT INTO tickets (cliente_id, descripcion, estado, prioridad, fecha_creacion) VALUES
(1, 'Error en módulo de ventas', 'abierto', 'alta', '2026-06-01'),
(2, 'Consulta por acceso de usuario', 'cerrado', 'media', '2026-06-03'),
(3, 'Reporte financiero lento', 'abierto', 'alta', '2026-06-05');
```

6. Revisar datos cargados ([06_check_tables.sh](./06_check_tables.sh)):

```sql
SELECT * FROM clientes;
SELECT * FROM tickets;
```

7. Crear backup manual ([07_create_backup.sh](./07_create_backup.sh)):

```bash
mkdir -p backups

pg_dump "postgresql://acmeadmin:AcmePass123!@$DB_HOST:$DB_PORT/acme" \
  > backups/acme_backup_$(date +%F_%H%M).sql
```

El archivo se genera en `02_rds/backups/`.

8. Probar consultas en SQLiteOnline ([08_query_fake_sqliteonline.sh](./08_query_fake_sqliteonline.sh)):

Copiar estas consultas en SQLiteOnline usando una version simplificada de las tablas `clientes` y `tickets`.

```sql
SELECT c.nombre, c.area, t.descripcion, t.prioridad
FROM tickets t
JOIN clientes c ON t.cliente_id = c.id;

SELECT prioridad, COUNT(*) AS cantidad
FROM tickets
GROUP BY prioridad;

SELECT *
FROM tickets
ORDER BY fecha_creacion DESC;
```

## Evidencia esperada

- Instancia `acme-postgres` creada.
- Base `acme` accesible por `psql`.
- Tablas `clientes` y `tickets` con datos de prueba.
- Consultas SQL ejecutadas.
- Backup `.sql` generado.
