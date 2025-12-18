class AddBankingDataAndMonthlyIncomeToCreditApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :credit_applications, :banking_data, :jsonb
    add_column :credit_applications, :monthly_income, :decimal, precision: 15, scale: 2, null: true
  end
end
