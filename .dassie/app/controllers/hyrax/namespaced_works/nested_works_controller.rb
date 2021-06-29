# Generated via
#  `rails generate hyrax:work NamespacedWorks::NestedWork`
module Hyrax
  # Generated controller for NamespacedWorks::NestedWork
  class NamespacedWorks::NestedWorksController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::NamespacedWorks::NestedWork

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::NamespacedWorks::NestedWorkPresenter
  end
end
