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
      errors = create_or_update_or_destroy

      if errors.empty?
        flash[:success] = _('Saved')
        head status: :ok
      else
        render json: errors, status: :internal_server_error
      end
    end

    private

    def create_or_update_or_destroy
      #old#
      # params.require(:templates).values.map do |param|
      #   if param[:id]
      #     r = @category.templates.find(param[:id])
      #     if param.delete(:_destroy) == '1' or (param[:name].blank? \
      #       and param[:templates_attributes].flat_map(&:values).all?(&:blank?))
      #       r.destroy
      #     else
      #       r.update_attributes(param)
      #     end
      #   else
      #     next if param[:name].blank? \
      #       and param[:templates_attributes].flat_map(&:values).all?(&:blank?)
      #     r = @category.templates.create(param)
      #   end
      #   r.errors.full_messages
      # end.flatten.compact

      @category.update_attributes(templates_attributes: \
                                  params.require(:templates_attributes))
      @category.errors.full_messages
    end

  end
end
