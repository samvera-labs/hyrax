# frozen_string_literal: true

RSpec.describe Hyrax::Schema do
  let(:attributes) { {} }
  let(:resource)   { resource_class.new(attributes) }

  let(:resource_class) do
    module Hyrax::Test::Schema
      class Resource < Hyrax::Resource; end
    end

    Hyrax::Test::Schema::Resource
  end

  after { Hyrax::Test.send(:remove_const, :Schema) }

  describe 'including' do
    it 'applies the specified schema' do
      expect { resource_class.include(Hyrax::Schema(:core_metadata)) }
        .to change { resource_class.attribute_names }
        .to include(:title, :date_uploaded, :date_modified, :depositor)
    end

    it 'raises for an missing schema' do
      expect { resource_class.include(Hyrax::Schema(:FAKE_SCHEMA)) } .to raise_error ArgumentError
    end

    it 'creates accessors for fields' do
      expect { resource_class.include(Hyrax::Schema(:core_metadata)) }
        .to change { resource_class.instance_methods }
        .to include(:title=, :date_modified=, :date_uploaded=, :depositor=,
                    :title, :date_modified, :date_uploaded, :depositor)
    end
  end

  describe 'core metadata' do
    let(:attributes) do
      { title: ['Comet in Moominland'],
        depositor: 'moomin@example.com',
        date_uploaded: DateTime.current,
        date_modified: DateTime.current }
    end

    before { resource_class.include(Hyrax::Schema(:core_metadata)) }

    it 'persists core attributes' do
      saved = Hyrax.persister.save(resource: resource)

      expect(saved).to have_attributes(**attributes)
    end
  end

  describe 'basic metadata' do
    let(:resource) { resource_class.new(attributes) }

    let(:attributes) do
      { abstract: ['lorem ipsum', 'sit dolor'],
        access_right: ['lorem ipsum', 'sit dolor'],
        alternative_title: [RDF::Literal('Finn Family Moomintroll', language: :en)],
        based_near: ['lorem ipsum', 'sit dolor'],
        contributor: ['moominpapa', 'moominmama'],
        creator: ['moomin'],
        date_created: [Time.zone.today, DateTime.current],
        description: ['lorem ipsum', 'sit dolor'],
        bibliographic_citation: ['lorem ipsum', 'sit dolor'],
        identifier: ['lorem ipsum', 'sit dolor'],
        import_url: 'http://example.com/import_url',
        keyword: ['moomin', 'family'],
        publisher: ['lorem ipsum', 'sit dolor'],
        label: 'Finn Family Moomintroll',
        language: ['lorem ipsum', 'sit dolor'],
        license: ['lorem ipsum', 'sit dolor'],
        relative_path: 'one/two/three/moomin.pdf',
        related_url: ['lorem ipsum', 'sit dolor'],
        resource_type: ['lorem ipsum', 'sit dolor'],
        rights_notes: ['lorem ipsum', 'sit dolor'],
        rights_statement: ['lorem ipsum', 'sit dolor'],
        source: ['lorem ipsum', 'sit dolor'],
        subject: ['lorem ipsum', 'sit dolor'] }
    end

    before { resource_class.include(Hyrax::Schema(:basic_metadata)) }

    it 'persists basic attributes' do
      saved = Hyrax.persister.save(resource: resource)

      matchers = attributes.each_with_object({}) do |(k, v), hash|
        v.is_a?(Array) ? hash[k] = contain_exactly(*v) : v
      end

      expect(saved).to have_attributes(**matchers)
    end
  end

  context 'with an ActiveFedora::Base model' do
    let(:resource_class) do
      module Hyrax::Test::Schema
        class Work < ActiveFedora::Base; end
      end

      Hyrax::Test::Schema::Work
    end

    describe 'including' do
      it 'applies the specified schema' do
        expect { resource_class.include(Hyrax::Schema(:core_metadata)) }
          .to change { resource_class.properties.keys }
          .to include('title', 'date_uploaded', 'date_modified', 'depositor')
      end

      it 'raises for an missing schema' do
        expect { resource_class.include(Hyrax::Schema(:FAKE_SCHEMA)) } .to raise_error ArgumentError
      end

      it 'creates accessors for fields' do
        expect { resource_class.include(Hyrax::Schema(:core_metadata)) }
          .to change { resource_class.instance_methods }
          .to include(:title=, :date_modified=, :date_uploaded=, :depositor=,
                      :title, :date_modified, :date_uploaded, :depositor)
      end
    end

    describe 'core metadata' do
      let(:attributes) do
        { title: ['Comet in Moominland'],
          depositor: 'moomin@example.com',
          date_uploaded: DateTime.current,
          date_modified: DateTime.current }
      end

      before { resource_class.include(Hyrax::Schema(:core_metadata)) }

      it 'persists core attributes' do
        resource.save
        saved = resource.reload

        expect(saved).to have_attributes(**attributes)
      end
    end

    describe 'basic metadata' do
      let(:resource) { resource_class.new(attributes) }

      let(:attributes) do
        { abstract: ['lorem ipsum', 'sit dolor'],
          access_right: ['lorem ipsum', 'sit dolor'],
          alternative_title: [RDF::Literal('Finn Family Moomintroll', language: :en)],
          based_near: ['lorem ipsum', 'sit dolor'],
          contributor: ['moominpapa', 'moominmama'],
          creator: ['moomin'],
          date_created: [Time.zone.today, DateTime.current],
          description: ['lorem ipsum', 'sit dolor'],
          bibliographic_citation: ['lorem ipsum', 'sit dolor'],
          identifier: ['lorem ipsum', 'sit dolor'],
          import_url: 'http://example.com/import_url',
          keyword: ['moomin', 'family'],
          publisher: ['lorem ipsum', 'sit dolor'],
          label: 'Finn Family Moomintroll',
          language: ['lorem ipsum', 'sit dolor'],
          license: ['lorem ipsum', 'sit dolor'],
          relative_path: 'one/two/three/moomin.pdf',
          related_url: ['lorem ipsum', 'sit dolor'],
          resource_type: ['lorem ipsum', 'sit dolor'],
          rights_notes: ['lorem ipsum', 'sit dolor'],
          rights_statement: ['lorem ipsum', 'sit dolor'],
          source: ['lorem ipsum', 'sit dolor'],
          subject: ['lorem ipsum', 'sit dolor'] }
      end

      before { resource_class.include(Hyrax::Schema(:basic_metadata)) }

      it 'persists basic attributes' do
        resource.save
        saved = resource.reload

        matchers = attributes.each_with_object({}) do |(k, v), hash|
          v.is_a?(Array) ? hash[k] = contain_exactly(*v) : v
        end

        expect(saved).to have_attributes(**matchers)
      end
    end
  end
end
