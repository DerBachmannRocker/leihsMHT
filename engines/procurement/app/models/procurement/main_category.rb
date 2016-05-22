module Procurement
  class MainCategory < ActiveRecord::Base

    has_many :budget_limits,
             dependent: :delete_all,
             inverse_of: :main_category
    accepts_nested_attributes_for :budget_limits,
                                  allow_destroy: true

    has_many :categories,
             dependent: :restrict_with_exception,
             inverse_of: :main_category
    accepts_nested_attributes_for :categories,
                                  allow_destroy: true,
                                  reject_if: :all_blank

    # TODO: belongs_to :procurement_attachment # image

    validates_presence_of :name
    validates_uniqueness_of :name

    def to_s
      name
    end

    default_scope { order(:name) }

  end
end
