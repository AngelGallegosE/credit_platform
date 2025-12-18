class AddValidationResultToCreditApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :credit_applications, :validation_result, :jsonb
  end
end
