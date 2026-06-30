# 01 - Almacenamiento

La solución contempla tres buckets S3 con roles específicos, cubriendo las métricas mínimas requeridas (1 bucket estándar + 1 archivado) y alcanzando el máximo permitido (3 buckets con políticas diferentes).

Implementación en Floci
La implementación se realizó mediante scripts de AWS CLI apuntando al endpoint local de Floci (http://localhost:4566). Se desarrollaron tres scripts organizados en una carpeta de proyecto, más un script maestro que los ejecuta en secuencia.

script.sh: script maestro que ejecuta los demás.
01_ crear_buckets.sh: Este script crea los tres buckets y les asigna etiquetas (tags) para facilitar la gestión de recursos por proyecto, área y empresa.
02_lifecycle_policies.sh: Cada bucket recibe una política de lifecycle diferente según el rol que cumple. Las políticas automatizan el movimiento de datos entre tiers de almacenamiento sin intervención manual.
03_backup_postgres.sh: Este script representa la integración con la base de datos acme-postgres ya existente en Floci. Genera un dump completo de la base acme, lo comprime y lo sube al bucket acme-db-backups con una estructura de carpetas por fecha.
