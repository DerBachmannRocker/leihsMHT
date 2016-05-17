class ProcurementCategories < ActiveRecord::Migration
  def up

    remove_foreign_key(:procurement_templates, column: 'template_category_id')
    change_table :procurement_templates do |t|
      t.remove :template_category_id
    end

    drop_table :procurement_template_categories
    create_table :procurement_categories do |t|
      t.string :name
      t.integer :parent_id, null: true
      # belongs :procurement_attachment # image

      t.index :name, unique: true
      t.index :parent_id
    end


    drop_table :procurement_group_inspectors
    create_table :procurement_category_inspectors do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :category, null: false

      t.index [:user_id, :category_id], unique: true
    end
    add_foreign_key(:procurement_category_inspectors, :procurement_categories, column: 'category_id')


    drop_table :procurement_budget_limits
    create_table :procurement_budget_limits do |t|
      t.belongs_to :budget_period, null: false
      t.belongs_to :category, null: false # only main-categories
      t.money :amount

      t.index [:budget_period_id, :category_id], unique: true, name: 'index_on_budget_period_id_and_category_id'
    end
    add_foreign_key(:procurement_budget_limits, :procurement_budget_periods, column: 'budget_period_id')
    add_foreign_key(:procurement_budget_limits, :procurement_categories, column: 'category_id')


    parent_cat = Procurement::Category.create name: 'Old Groups', parent: nil
    sub_cat = Procurement::Category.create name: 'Existing requests', parent: parent_cat

    remove_foreign_key(:procurement_requests, column: 'group_id')
    rename_column(:procurement_requests, :group_id, :category_id)
    Procurement::Request.update_all(category_id: sub_cat)
    change_column_null :procurement_requests, :category_id, false
    add_foreign_key(:procurement_requests, :procurement_categories, column: 'category_id')


    change_table :procurement_templates do |t|
      t.belongs_to :category, null: false
    end
    Procurement::Template.update_all(category_id: sub_cat)
    add_foreign_key(:procurement_templates, :procurement_categories, column: 'category_id')


    drop_table :procurement_groups

  end
end
