require_dependency 'procurement/application_controller'

module Procurement
  class CategoriesController < ApplicationController

    before_action do
      authorize Category
    end

    before_action only: [:create, :update] do
      params[:category][:inspector_ids] = \
        params[:category][:inspector_ids].split(',').map &:to_i
    end

    def index
      @categories = Category.main
      respond_to do |format|
        format.html
        format.json { render json: @categories }
      end
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
      params.require(:categories).values.map do |param|
        if param[:id]
          r = Procurement::Category.find(param[:id])
          if param.delete(:_destroy) == '1' or param[:name].blank?
            r.destroy
          else
            r.update_attributes(param)
          end
        else
          next if param[:name].blank?
          r = Procurement::Category.create(param)
        end
        r.errors.full_messages
      end.flatten.compact
    end

  end
end
