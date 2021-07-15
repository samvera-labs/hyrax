# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Builds a schema module for a Valkyrie resource. The schema itself is
  # resolved by schema loader, which must respond to
  # `#attributes_for(schema: :name)` with a hash from attribute names to
  # `Dry::Type` types.
  #
  # For the default schema loader, configuration is loaded from
  # `config/metadata/[name]}.yaml`. Custom schema loaders can be provided
  # for other types.
  #
  # @note `Valkyrie::Resources`/`Hyrax::Resources` are not required to use this
  # interface, and may define custom attributes using the base
  # `Valkyrie::Resource.attribute` interface. This mechanism is provided to
  # allow schemas to be defined in a unified way that don't require programmer
  # intervention ("configurable schemas"). While the default usage defines
  # schemas in application configuration, they could also be held in repository
  # storage, an external schema service, etc... by using a custom schema loader.
  #
  # @param [Symbol] schema_name
  #
  # @return [Module] a module that, when included, applies a schema to a
  #   `Valkyire::Resource`
  #
  # @example
  #   class Monograph < Valkyrie::Resource
  #     include Hyrax::Schema(:book)
  #   end
  #
  # @example with a custom schema loader
  #   class Monograph < Valkyrie::Resource
  #     include Hyrax::Schema(:book, schema_loader: MySchemaLoader.new)
  #   end
  #
  # @since 3.0.0
  def self.Schema(schema_name, **options)
    Hyrax::Schema.new(schema_name, **options)
  end

  ##
  # @api private
  #
  # A module specifying a Schema (set of attributes and types) that can be
  # applied to a `Valkyrie::Resource`. This provides the internals for the
  # recommended module builder syntax: `Hyrax::Schema(:schema_name)`
  #
  # @see .Schema
  class Schema < Module
    ##
    # @!attribute [r] name
    #   @return [Symbol]
    attr_reader :name

    ##
    # @param [Symbol] schema_name
    #
    # @note use Hyrax::Schema(:my_schema) instead
    #
    # @api private
    def initialize(schema_name, schema_loader: SimpleSchemaLoader.new)
      @name = schema_name
      @schema_loader = schema_loader
    end

    ##
    # @return [Hash{Symbol => Dry::Types::Type}]
    def attributes
      @schema_loader.attributes_for(schema: name)
    end

    ##
    # @return [Hash{Symbol => Hash}]
    def attributes_config
      @schema_loader.attributes_config_for(schema: name)
    end

    ##
    # @return [String]
    def inspect
      "#{self.class}(#{@name})"
    end

    private

    ##
    # @param [Module] descendant
    #
    # @api private
    def included(descendant)
      super
      if descendant < Valkyrie::Resource
        descendant.attributes(attributes)
      else
        attributes_config.each do |name, config|
          descendant.property(name, config.symbolize_keys)
        end
      end
    end
  end
end
