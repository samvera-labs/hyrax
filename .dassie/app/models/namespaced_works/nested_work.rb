# Generated via
#  `rails generate hyrax:work NamespacedWorks::NestedWork`
class NamespacedWorks::NestedWork < ActiveFedora::Base
  property :created, predicate: ::RDF::Vocab::DC.created, class_name: TimeSpan
  include ::Hyrax::WorkBehavior

  self.indexer = NamespacedWorks::NestedWorkIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata
  accepts_nested_attributes_for :created
end
