# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::Indexer do
  subject(:indexer) { indexer_class.new(resource: work) }
  let(:work)        { FactoryBot.build(:hyrax_work) }

  let(:indexer_class) do
    Class.new(Hyrax::ValkyrieIndexer) do
      include Hyrax::Indexer(:core_metadata)
    end
  end

  context 'with core metadata schema' do
    let(:resource) { work }
    it_behaves_like 'a Core metadata indexer'
  end

  describe '#to_solr' do
    it 'builds a document to index the core schema' do
      expect(indexer.to_solr).to include(title_tesim: work.title)
    end

    context 'with a custom schema'
  end

  context 'with a Hyrax::WorkIndexer' do
    subject(:indexer) { indexer_class.new(work) }
    let(:work)        { FactoryBot.build(:work) }

    let(:indexer_class) do
      Class.new(Hyrax::WorkIndexer) do
        include Hyrax::Indexer(:core_metadata)
      end
    end

    context 'with core metadata schema' do
      let(:resource) { work }
      it_behaves_like 'a Core metadata indexer'
    end

    describe '#to_solr' do
      it 'builds a document to index the core schema' do
        expect(indexer.generate_solr_document).to include(title_tesim: work.title)
      end

      context 'with a custom schema'
    end
  end
end
