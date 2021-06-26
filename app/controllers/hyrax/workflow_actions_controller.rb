# frozen_string_literal: true
module Hyrax
  class WorkflowActionsController < ApplicationController
    DEFAULT_FORM_CLASS = Hyrax::Forms::WorkflowActionForm

    before_action :authenticate_user!

    def update
      if workflow_action_form.save
        after_update_response
      else
        respond_to do |wants|
          wants.html { render 'hyrax/base/unauthorized', status: :unauthorized }
          wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: curation_concern.errors }) }
        end
      end
    end

    private

    def curation_concern
      @curation_concern ||= Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: params[:id], use_valkyrie: Hyrax.config.use_valkyrie?)
    end

    def workflow_action_form
      @workflow_action_form ||= DEFAULT_FORM_CLASS.new(
        current_ability: current_ability,
        work: curation_concern,
        attributes: workflow_action_params
      )
    end

    def workflow_action_params
      params.require(:workflow_action).permit(:name, :comment)
    end

    def after_update_response
      respond_to do |wants|
        wants.html { redirect_to [main_app, curation_concern], notice: "The #{curation_concern.human_readable_type} has been updated." }
        wants.json { render 'hyrax/base/show', status: :ok, location: polymorphic_path([main_app, curation_concern]) }
      end
    end
  end
end
