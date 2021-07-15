# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # @param [Symbol] schema_name
  #
  # @since 3.0.0
  def self.FormFields(schema_name, **options)
    Hyrax::FormFields.new(schema_name, **options)
  end

  ##
  # @api private
  #
  # @see .FormFields
  class FormFields < Module
    attr_reader :name

    ##
    # @api private
    #
    # @param [Symbol] schema_name
    # @param [#form_definitions_for] definition_loader
    #
    # @note use Hyrax::FormFields(:my_schema) instead
    def initialize(schema_name, definition_loader: SimpleSchemaLoader.new)
      @name = schema_name
      @definition_loader = definition_loader
    end

    ##
    # @return [Hash{Symbol => Hash{Symbol => Object}}]
    def form_field_definitions
      @definition_loader.form_definitions_for(schema: name)
    end

    ##
    # @return [String]
    def inspect
      "#{self.class}(#{@name})"
    end

    private

    def included(descendant)
      super

      if descendant == Hyrax::Forms::WorkForm || descendant < Hyrax::Forms::WorkForm
        descendant.terms ||= []
        descendant.required_fields ||= []
        # descendant.primary_terms ||= []

        form_field_definitions.each do |field_name, options|
          descendant.terms += [field_name.to_sym]
          descendant.required_fields += [field_name.to_sym] if options[:required]
          # descendant.primary_terms += [field_name.to_sym] if options[:primary]
        end
      else
        form_field_definitions.each do |field_name, options|
          descendant.property field_name.to_sym, options.merge(display: true, default: [])
        end
      end
    end
  end
end
