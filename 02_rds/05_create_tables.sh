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