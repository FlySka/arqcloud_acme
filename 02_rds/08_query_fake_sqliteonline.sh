SELECT c.nombre, c.area, t.descripcion, t.prioridad
FROM tickets t
JOIN clientes c ON t.cliente_id = c.id;

SELECT prioridad, COUNT(*) AS cantidad
FROM tickets
GROUP BY prioridad;

SELECT *
FROM tickets
ORDER BY fecha_creacion DESC;