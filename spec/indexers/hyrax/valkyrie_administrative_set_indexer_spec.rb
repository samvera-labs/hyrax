# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::AdministrativeSetIndexer do
  subject(:service) { described_class.new(resource: admin_set) }
  let(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, title: [admin_set_title]) }
  let(:admin_set_title) { 'An Admin Set' }

  it 'is resolved from an admin set' do
    expect(Hyrax::ValkyrieIndexer.for(resource: admin_set))
      .to be_a described_class
  end

  describe '#to_solr' do
    it 'includes default attributes ' do
      expect(subject.to_solr)
        .to include 'generic_type_si' => 'Admin Set', 'title_tesim' => [admin_set_title]
    end
  end
end
