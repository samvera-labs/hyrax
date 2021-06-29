module Hyrax
  class UsersController < ApplicationController
    include Blacklight::SearchContext
    prepend_before_action :find_user, only: [:show]

    helper Hyrax::TrophyHelper

    def index
      authenticate_user! if Flipflop.hide_users_list?
      @users = search(params[:uq])
    end

    # Display user profile
    def show
      user = ::User.from_url_component(params[:id])
      return redirect_to root_path, alert: "User '#{params[:id]}' does not exist" if user.nil?
      @presenter = Hyrax::UserProfilePresenter.new(user, current_ability)
    end

    private

      # TODO: this should move to a service.
      #
      # @todo Given that this method sends its methods to ::User, I
      # believe it could be extracted to User; I don't think the
      # base_query can be as it may require controller level context
      #
      # Returns a list of users excluding the system users and guest_users
      # @param query [String] the query string
      def search(query)
        base = ::User
        # TODO: Remove send wrapping of sanitize_sql_like when support for Rails 5.1 is dropped.
        clause = query.blank? ? nil : "%#{base.send(:sanitize_sql_like, query.downcase)}%"
        base = base.where(*Array.wrap(base_query))
        # This may have some DB adapter specific behavior, which is
        # definitely logic I'd like to keep out of a controller.
        base = base.where("LOWER(#{Hydra.config.user_key_field}) LIKE :clause OR LOWER(display_name) LIKE :clause", clause: clause) if clause.present?
        base.registered
            .without_system_accounts
            .references(:trophies)
            .order(sort_value)
            .page(params[:page]).per(10)
      end

      # @api public
      #
      # You can override base_query to return a list of arguments
      #
      # @note This changed a default from `[nil]` to `{}`.  In part
      # there were errors in the specs regarding this behavior.
      #
      # @example
      #   def base_query
      #     { custom_field: true }
      #   end
      #
      # @return Hash (or more appropriate something that maps to the
      # method signature of ActiveRecord::Base.where)
      def base_query
        {}
      end

      def find_user
        @user = ::User.from_url_component(params[:id])
        redirect_to root_path, alert: "User does not exist" unless @user
      end

      def sort_value
        sort = params[:sort].blank? ? "name" : params[:sort]
        case sort
        when 'name'
          'display_name'
        when 'name desc'
          'display_name DESC'
        when 'login'
          Hydra.config.user_key_field
        when 'login desc'
          "#{Hydra.config.user_key_field} DESC"
        else
          sort
        end
      end
  end
end
