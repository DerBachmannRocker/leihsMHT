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

    before_action only: [:edit, :update, :destroy] do
      @category = Category.find(params[:id])
    end

    def index
      @categories = Category.all
      respond_to do |format|
        format.html
        format.json { render json: @categories }
      end
    end

    def new
      @category = Category.new
      render :edit
    end

    def create
      @category = Category.create(params[:category])
      if @category.valid?
        redirect_to categories_path
      else
        flash.now[:error] = @category.errors.full_messages
        render :edit
      end
    end

    def edit
    end

    def update
      @category.update_attributes(params[:category])
      flash[:success] = _('Saved')
      redirect_to categories_path
    end

    def destroy
      @category.destroy
      redirect_to categories_path
    end

  end
end
