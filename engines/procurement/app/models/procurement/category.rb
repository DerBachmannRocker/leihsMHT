module Procurement
  class Category < ActiveRecord::Base

    has_many :category_inspectors, dependent: :delete_all
    has_many :inspectors, -> { order('firstname, lastname') },
             through: :category_inspectors,
             source: :user
    has_many :requests, dependent: :restrict_with_exception

    has_many :templates, -> { order(:article_name) }, dependent: :delete_all
    accepts_nested_attributes_for :templates,
                                  allow_destroy: true,
                                  reject_if: :all_blank

    belongs_to :main_category

    # TODO: belongs_to :procurement_attachment # image

    validates_presence_of :name, :main_category
    validates_uniqueness_of :name

    def to_s
      main_category.name + ' > ' + name
    end

    default_scope { order(:name) }

    ########################################################

    def inspectable_by?(user)
      category_inspectors.where(user_id: user).exists?
    end

    def inspectable_or_readable_by?(user)
      Procurement::Category.inspector_of_any_category_or_admin?(user)
    end

    class << self
      def inspector_of_any_category?(user)
        Procurement::CategoryInspector.where(user_id: user).exists?
      end

      def inspector_of_any_category_or_admin?(user)
        inspector_of_any_category?(user) or Procurement::Access.admin?(user)
      end
    end

  end
end
