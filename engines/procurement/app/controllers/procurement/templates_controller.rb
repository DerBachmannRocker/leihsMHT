require_dependency 'procurement/application_controller'

module Procurement
  class TemplatesController < ApplicationController
    def self.policy_class
      CategoryPolicy
    end

    before_action do
      @category = Procurement::Category.find(params[:category_id])
      authorize @category, :inspectable_by_user?
    end

    def index
    end

    def create
      @category.update_attributes(templates_attributes: \
                                  params.require(:templates_attributes))

      errors = @category.errors.full_messages

      if errors.empty?
        flash[:success] = _('Saved')
        head status: :ok
      else
        render json: errors, status: :internal_server_error
      end
    end

  end
end
