-- =============================================================================
-- Trigger: trg_auditoria_precio_plato
-- =============================================================================
-- Propósito:
--   Mantener un historial completo de todos los cambios de precio en el
--   menú, permitiendo análisis de rentabilidad histórica, auditorías
--   administrativas y seguimiento de estrategias de pricing.
--
-- Descripción:
--   Cada vez que se modifica el precio_base de un plato, este trigger:
--   1. Verifica que el precio realmente haya cambiado (evita registros redundantes)
--   2. Inserta un registro en auditoria_precio_plato con:
--      - Precio anterior
--      - Precio nuevo
--      - Usuario de base de datos que realizó el cambio
--      - Timestamp exacto del cambio
--
--   Esta información es valiosa para:
--   - Análisis de evolución de precios
--   - Correlación con variaciones en ventas
--   - Auditorías administrativas
--   - Cumplimiento de políticas de pricing
--
-- Regla de negocio:
--   "Todo cambio de precio de un plato debe quedar registrado para efectos
--   de análisis de rentabilidad y auditoría administrativa."
--
-- Evento: AFTER UPDATE sobre plato
-- Tipo: FOR EACH ROW
--
-- Dependencias:
--   - Tabla: plato (disparador)
--   - Tabla: auditoria_precio_plato (almacén de auditoría)
--
-- Uso recomendado:
--   -- Historial de cambios de un plato específico
--   SELECT * FROM auditoria_precio_plato 
--   WHERE plato_id = 5 
--   ORDER BY fecha_cambio DESC;
--
--   -- Cambios de precio en el último mes
--   SELECT 
--     p.nombre,
--     app.precio_anterior,
--     app.precio_nuevo,
--     app.fecha_cambio,
--     app.usuario_db
--   FROM auditoria_precio_plato app
--   INNER JOIN plato p ON app.plato_id = p.id
--   WHERE app.fecha_cambio >= NOW() - INTERVAL '1 month'
--   ORDER BY app.fecha_cambio DESC;
--
-- Nota de negocio:
--   Este trigger NO bloquea ni modifica la operación de actualización,
--   solo registra el cambio. Es completamente transparente para el usuario.
--
-- Nota técnica:
--   La condición IF evita insertar registros cuando se actualiza el plato
--   pero el precio permanece igual, optimizando el espacio en auditoría.
--
-- Fecha creación: 2026-03-16
-- =============================================================================

-- Función del trigger
CREATE OR REPLACE FUNCTION fn_auditoria_precio_plato()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Solo auditar si el precio realmente cambió
  IF NEW.precio_base <> OLD.precio_base THEN
    INSERT INTO auditoria_precio_plato (
      plato_id,
      precio_anterior,
      precio_nuevo,
      usuario_db,
      fecha_cambio
    )
    VALUES (
      NEW.id,
      OLD.precio_base,
      NEW.precio_base,
      current_user,
      NOW()
    );
  END IF;

  RETURN NEW;
END;
$$;

-- Crear el trigger
CREATE TRIGGER trg_auditoria_precio_plato
  AFTER UPDATE ON plato
  FOR EACH ROW
  EXECUTE FUNCTION fn_auditoria_precio_plato();

-- =============================================================================
-- Fin del trigger: trg_auditoria_precio_plato
-- =============================================================================
