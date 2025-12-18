class CreateCreditApplicationEvents < ActiveRecord::Migration[8.1]
  def up
    # Crear la tabla credit_application_events
    create_table :credit_application_events do |t|
      t.bigint :credit_application_id, null: false
      t.string :event_type, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :credit_application_events, :credit_application_id
    add_index :credit_application_events, :event_type
    add_index :credit_application_events, :created_at

    # Crear función para capturar cambios
    execute <<-SQL
      CREATE OR REPLACE FUNCTION log_credit_application_changes()
      RETURNS TRIGGER AS $$
      DECLARE
        event_type_value TEXT;
        metadata_value JSONB;
        changed_fields JSONB := '{}'::JSONB;
        old_record JSONB;
        new_record JSONB;
        key TEXT;
      BEGIN
        -- Determinar el tipo de evento
        IF TG_OP = 'INSERT' THEN
          event_type_value := 'created';
          new_record := to_jsonb(NEW);
          -- Guardar todos los valores nuevos
          metadata_value := jsonb_build_object(
            'new_values', new_record
          );
        ELSIF TG_OP = 'UPDATE' THEN
          event_type_value := 'updated';
          old_record := to_jsonb(OLD);
          new_record := to_jsonb(NEW);

          -- Comparar y guardar solo los campos que cambiaron
          FOR key IN SELECT jsonb_object_keys(new_record) LOOP
            IF old_record->>key IS DISTINCT FROM new_record->>key THEN
              changed_fields := changed_fields || jsonb_build_object(
                key, jsonb_build_object(
                  'old_value', old_record->key,
                  'new_value', new_record->key
                )
              );
            END IF;
          END LOOP;

          metadata_value := jsonb_build_object(
            'changed_fields', changed_fields
          );
        ELSIF TG_OP = 'DELETE' THEN
          event_type_value := 'deleted';
          old_record := to_jsonb(OLD);
          -- Guardar todos los valores antiguos
          metadata_value := jsonb_build_object(
            'old_values', old_record
          );
        END IF;

        -- Insertar el evento
        INSERT INTO credit_application_events (
          credit_application_id,
          event_type,
          metadata,
          created_at,
          updated_at
        ) VALUES (
          COALESCE(NEW.id, OLD.id),
          event_type_value,
          metadata_value,
          NOW(),
          NOW()
        );

        -- Retornar el registro apropiado
        IF TG_OP = 'DELETE' THEN
          RETURN OLD;
        ELSE
          RETURN NEW;
        END IF;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # Crear el trigger
    execute <<-SQL
      CREATE TRIGGER credit_application_changes_trigger
      AFTER INSERT OR UPDATE OR DELETE ON credit_applications
      FOR EACH ROW
      EXECUTE FUNCTION log_credit_application_changes();
    SQL
  end

  def down
    # Eliminar el trigger
    execute <<-SQL
      DROP TRIGGER IF EXISTS credit_application_changes_trigger ON credit_applications;
    SQL

    # Eliminar la función
    execute <<-SQL
      DROP FUNCTION IF EXISTS log_credit_application_changes();
    SQL

    # Eliminar la tabla
    drop_table :credit_application_events
  end
end
