module Procurement
  class BudgetLimit < ActiveRecord::Base

    belongs_to :budget_period
    belongs_to :category

    validates_presence_of :budget_period, :category, :amount
    validates_uniqueness_of :budget_period_id, scope: :category_id

    monetize :amount_cents

  end
end
