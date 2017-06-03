class AddColumnCarriageToOrder < ActiveRecord::Migration[5.0]
  def change
    add_column :orders, :carriage, :decimal, precision: 10, scale: 3, default: 0.00
  end
end
