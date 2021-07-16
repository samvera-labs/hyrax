# frozen_string_literal: true

##
# {Sipity} is a workflow/state engine.
module Sipity
  ##
  # Cast a given input (e.g. a +::User+ or {Hyrax::Group} to a {Sipity::Agent}).
  #
  # @param input [Object]
  def Agent(input, &block) # rubocop:disable Naming/MethodName
    result = case input
             when Sipity::Agent
               input
             end

    handle_conversion(input, result, :to_sipity_agent, &block)
  end
  module_function :Agent

  ##
  # Cast an object to an Entity
  # rubocop:disable Naming/MethodName, Metrics/CyclomaticComplexity, Metrics/MethodLength
  def Entity(input, &block)
    result = case input
             when Sipity::Entity
               input
             when URI::GID, GlobalID
               Entity.find_by(proxy_for_global_id: input.to_s)
             when SolrDocument
               Entity(input.to_model)
             when Draper::Decorator
               Entity(input.model)
             when Sipity::Comment
               Entity(input.entity)
             when Valkyrie::Resource
               Entity(Hyrax::GlobalID(input))
             else
               Entity(input.to_global_id) if input.respond_to?(:to_global_id)
             end

    handle_conversion(input, result, :to_sipity_entity, &block)
  rescue URI::GID::MissingModelIdError
    Entity(nil)
  end
  module_function :Entity
  # rubocop:enable Naming/MethodName, Metrics/CyclomaticComplexity, Metrics/MethodLength

  ##
  # Cast an object to an Role
  def Role(input, &block) # rubocop:disable Naming/MethodName
    result = case input
             when Sipity::Role
               input
             when String, Symbol
               Sipity::Role.find_or_create_by(name: input)
             end

    handle_conversion(input, result, :to_sipity_role, &block)
  end
  module_function :Role

  ##
  # Cast an object to a WorkflowAction in a given workflow
  def WorkflowAction(input, workflow, &block) # rubocop:disable Naming/MethodName
    workflow_id = PowerConverter.convert_to_sipity_workflow_id(workflow)

    result = case input
             when WorkflowAction
               input if input.workflow_id == workflow_id
             when String, Symbol
               WorkflowAction.find_by(workflow_id: workflow_id, name: input.to_s)
             end

    handle_conversion(input, result, :to_sipity_action, &block)
  end
  module_function :WorkflowAction

  ##
  # Cast an object to a WorkflowState in a given workflow
  def WorkflowState(input, workflow, &block) # rubocop:disable Naming/MethodName
    result = case input
             when Sipity::WorkflowState
               input
             when Symbol, String
               WorkflowState.find_by(workflow_id: workflow.id, name: input)
             end

    handle_conversion(input, result, :to_sipity_workflow_state, &block)
  end
  module_function :WorkflowState

  ##
  # A parent error class for all workflow errors caused by bad state
  class StateError < RuntimeError; end

  class ConversionError < PowerConverter::ConversionError
    def initialize(value, **options)
      options[:scope] ||= nil
      options[:to]    ||= nil
      super(value, options)
    end
  end

  ##
  # Provides compatibility with the old `PowerConverter` conventions
  def handle_conversion(input, result, method_name)
    result ||= input.try(method_name)
    return result unless result.nil?
    return yield if block_given?

    raise ConversionError.new(input) # rubocop:disable Style/RaiseArgs
  end
  module_function :handle_conversion
end
