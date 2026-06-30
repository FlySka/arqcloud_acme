# Portafolio 3 - Infraestructura Viva

Repositorio del portafolio del modulo 4 para la propuesta "Infraestructura Viva" de Soluciones Digitales ACME.

El proyecto documenta una demo local de servicios tipo AWS usando Floci en Docker. Cada carpeta numerada corresponde a un capitulo o leccion del portafolio.

## Capitulos

1. **[Almacenamiento](01_almacenamiento/almacenamiento.md)**
2. **[Bases de datos relacionales - RDS](02_rds/rds.md)**
3. **[Bases de datos NoSQL](03_nosql/nosql.md)**
4. **[Servicios de computo](04_computo/computo.md)**
5. **[Servicio de red en la nube](05_red/red.md)**
6. **[Notificacion y mensajeria](06_mensajeria/mensajeria.md)**
7. **[Alojamiento web y contenidos](07_alojamiento_web/alojamiento_web.md)** 

## Requisitos

- WSL2 con Docker funcionando.
- AWS CLI instalado dentro de WSL2.
- Cliente `psql` y `pg_dump` para el capitulo RDS.

## Floci en Docker

1. Crear una carpeta local para Floci:

```bash
mkdir -p ~/floci
cd ~/floci
```

2. Crear un `docker-compose.yml` minimo:

```yaml
services:
  floci:
    image: floci/floci:latest
    ports:
      - "4566:4566"
      - "7001-7099:7001-7099"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/app/data
    environment:
      FLOCI_SERVICES_RDS_PROXY_BASE_PORT: "7001"
```

3. Levantar Floci:

```bash
docker compose up -d
```

4. Configurar la AWS CLI para usar Floci:

```bash
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
```

5. Validar conectividad:

```bash
aws sqs list-queues
```

Para dejar las variables fijas, agregarlas al archivo `~/.bashrc`.

## Referencias

- [Floci Quick Start](https://floci.io/floci/getting-started/quick-start/)
- [Floci Services Overview](https://floci.io/floci/services/)
