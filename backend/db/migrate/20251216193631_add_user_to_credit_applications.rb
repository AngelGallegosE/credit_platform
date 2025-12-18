class AddUserToCreditApplications < ActiveRecord::Migration[8.1]
  def up
    # Agregar columna user_id a la tabla particionada
    # PostgreSQL automáticamente la agregará a todas las particiones
    add_column :credit_applications, :user_id, :bigint, null: false

    # Agregar índice para user_id
    add_index :credit_applications, :user_id, name: "index_credit_applications_on_user_id"

    # Agregar foreign key constraint
    # Nota: En tablas particionadas, la foreign key se crea en la tabla principal
    # y se propaga automáticamente a las particiones
    add_foreign_key :credit_applications, :users, column: :user_id
  end

  def down
    remove_foreign_key :credit_applications, :users
    remove_index :credit_applications, name: "index_credit_applications_on_user_id"
    remove_column :credit_applications, :user_id
  end
end
