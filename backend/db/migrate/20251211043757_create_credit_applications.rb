class CreateCreditApplications < ActiveRecord::Migration[8.1]
  def up
    # Crear la tabla principal particionada por LIST en country
    execute <<-SQL
      CREATE TABLE credit_applications (
        id BIGSERIAL NOT NULL,
        country VARCHAR NOT NULL,
        full_name VARCHAR NOT NULL,
        requested_amount DECIMAL(15, 2) NOT NULL,
        application_date DATE NOT NULL,
        status VARCHAR NOT NULL,
        created_at TIMESTAMP(6) NOT NULL,
        updated_at TIMESTAMP(6) NOT NULL,
        PRIMARY KEY (id, country)
      ) PARTITION BY LIST (country);
    SQL

    # Crear partición para México
    execute <<-SQL
      CREATE TABLE credit_applications_mexico PARTITION OF credit_applications
      FOR VALUES IN ('mexico');
    SQL

    # Crear partición para Portugal
    execute <<-SQL
      CREATE TABLE credit_applications_portugal PARTITION OF credit_applications
      FOR VALUES IN ('portugal');
    SQL

    # Crear índices
    add_index :credit_applications, :country, name: "index_credit_applications_on_country"
    add_index :credit_applications, [ :country, :full_name ], name: "index_credit_applications_on_country_and_full_name"
    add_index :credit_applications, [ :country, :status ], name: "index_credit_applications_on_country_and_status"
    add_index :credit_applications, :application_date, name: "index_credit_applications_on_application_date"
    add_index :credit_applications, :status, name: "index_credit_applications_on_status"
  end

  def down
    drop_table :credit_applications if table_exists?(:credit_applications)
  end
end
