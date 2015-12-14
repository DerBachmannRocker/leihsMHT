module Procurement
  class ApplicationController < ActionController::Base
    include MainHelpers

    before_action :require_login, :require_admins, except: :root

    def root
      if current_user and Procurement::Group.inspector_of_any_group_or_admin?(current_user)
        redirect_to filter_overview_requests_path
      elsif is_procurement_requester?
        redirect_to overview_user_requests_path(current_user)
      # elsif is_procurement_admin?
      #   redirect_to budget_periods_path
      end
    end

    protected

    helper_method :is_procurement_admin?, :is_procurement_requester?

    def is_procurement_admin?
      current_user and (Access.is_admin?(current_user) or (Access.admins.empty? and is_admin?))
    end

    def is_procurement_requester?
      current_user and Access.requesters.where(user_id: current_user).exists?
    end

    private

    def require_login
      unless current_user
        flash[:error] = _('You are not logged in')
        redirect_to root_path
      end
    end

    def require_admins
      if Access.admins.empty?
        flash[:error] = _('No admins defined yet')
        if is_procurement_admin?
          redirect_to users_path
        else
          redirect_to root_path
        end
      end
    end

    def require_admin_role
      redirect_to root_path unless Access.is_admin?(current_user)
    end

  end
end