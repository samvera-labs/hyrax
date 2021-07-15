# frozen_string_literal: true

# These shared specs test various aspects of valkyrie based indexers by calling the #to_solr method.
# All tests require two variables to be set in the caller using let statements:
#   * indexer_class - class of the indexer being tested
#   * resource - a Hyrax::Resource that defines attributes and values consistent with the indexer
#
# NOTE: It is important that the resource has required values that the indexer #to_solr customizations expects to be available.
RSpec.shared_examples 'a Hyrax::Resource indexer' do
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::Resource' unless defined?(resource) && resource.kind_of?(Hyrax::Resource)
    resource.alternate_ids = ids
  end
  subject(:indexer)  { indexer_class.new(resource: resource) }
  let(:ids)          { ['id1', 'id2'] }

  describe '#to_solr' do
    it 'indexes base resource fields' do
      expect(indexer.to_solr)
        .to include(has_model_ssim: resource.class.name,
                    human_readable_type_tesim: resource.human_readable_type,
                    alternate_ids_sim: a_collection_containing_exactly(*ids))
    end
  end
end

RSpec.shared_examples 'a permission indexer' do
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    # NOTE: resource must be persisted for these tests to pass
    raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::Resource' unless defined?(resource) && resource.kind_of?(Hyrax::Resource)
    Hyrax::VisibilityWriter.new(resource: resource)
        .assign_access_for(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
    resource.permission_manager.edit_groups = edit_groups
    resource.permission_manager.edit_users  = edit_users
    resource.permission_manager.read_users  = read_users
    resource.permission_manager.acl.save
  end
  subject(:indexer) { indexer_class.new(resource: resource) }
  let(:edit_groups) { [:managers] }
  let(:edit_users)  { [FactoryBot.create(:user)] }
  let(:read_users)  { [FactoryBot.create(:user)] }

  describe '#to_solr' do
    it 'indexes read permissions' do
      expect(indexer.to_solr)
        .to include(Hydra.config.permissions.read.group => [Hyrax.config.public_user_group_name],
                    Hydra.config.permissions.read.individual => read_users.map(&:user_key))
    end

    it 'indexes edit permissions' do
      expect(indexer.to_solr)
        .to include(Hydra.config.permissions.edit.group => edit_groups.map(&:to_s),
                    Hydra.config.permissions.edit.individual => edit_users.map(&:user_key))
    end
  end
end

RSpec.shared_examples 'a visibility indexer' do
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::Resource' unless defined?(resource) && resource.kind_of?(Hyrax::Resource)
    # optionally can pass in default_visibility by setting it with a let statement if your application changes the default; Hyrax defines this as 'restricted'
    # See samvera/hyrda-head hydra-access-controls/app/models/concerns/hydra/access_controls/access_rights.rb for possible VISIBILITY_TEXT_VALUE_...'
  end
  subject(:indexer)  { indexer_class.new(resource: resource) }

  describe '#to_solr' do
    it 'indexes default visibility as restricted or passed in default' do
      expected_value = defined?(default_visibility) ? default_visibility : 'restricted'
      expect(indexer.to_solr).to include(visibility_ssi: expected_value)
    end

    context 'when resource is public' do
      before do
        Hyrax::VisibilityWriter.new(resource: resource)
          .assign_access_for(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      end

      it 'indexes as open' do
        expect(indexer.to_solr).to include(visibility_ssi: 'open')
      end
    end
  end
end

RSpec.shared_examples 'a Core metadata indexer' do
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    # NOTE: The resource's class is expected to have or inherit `include Hyrax::Schema(:core_metadata)`
    if indexer_class < Hyrax::ValkyrieIndexer
      raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::Resource' unless defined?(resource) && resource.kind_of?(Hyrax::Resource)
      @indexer_method_name = :to_solr
    else
      raise 'resource must be set with `let(:resource)` and is expected to be a kind of ActiveFedora::Base' unless defined?(resource) && resource.kind_of?(ActiveFedora::Base)
      @indexer_method_name = :generate_solr_document
    end
    resource.title = titles
  end
  subject(:indexer) do
    if indexer_class < Hyrax::ValkyrieIndexer
      indexer_class.new(resource: resource)
    else
      indexer_class.new(resource)
    end
  end
  let(:titles)      { ['Comet in Moominland', 'Finn Family Moomintroll'] }

  describe '#to_solr' do
    it 'indexes title as text' do
      expect(indexer.send(@indexer_method_name))
        .to include(title_tesim: a_collection_containing_exactly(*titles))
    end

    it 'indexes title as string' do
      expect(indexer.send(@indexer_method_name))
        .to include(title_sim: a_collection_containing_exactly(*titles))
    end
  end
end

RSpec.shared_examples 'a Basic metadata indexer' do
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    # NOTE: The resource's class is expected to to have or inherit `include Hyrax::Schema(:basic_metadata)`
    raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::Resource' unless defined?(resource) && resource.kind_of?(Hyrax::Resource)
    attributes.each { |k, v| resource.set_value(k, v) }
  end
  subject(:indexer) { indexer_class.new(resource: resource) }

  let(:attributes) do
    {
      based_near: ['helsinki', 'finland'],
      date_created: ['tuesday'],
      keyword: ['comic strip'],
      related_url: ['http://example.com/moomin'],
      resource_type: ['book'],
      subject: ['moomins', 'snorks']
    }
  end

  describe '#to_solr' do
    it 'indexes basic metadata' do
      expect(indexer.to_solr)
        .to include(based_near_tesim: a_collection_containing_exactly(*attributes[:based_near]),
                    based_near_sim: a_collection_containing_exactly(*attributes[:based_near]),
                    date_created_tesim: a_collection_containing_exactly(*attributes[:date_created]),
                    keyword_sim: a_collection_containing_exactly(*attributes[:keyword]),
                    related_url_tesim: a_collection_containing_exactly(*attributes[:related_url]),
                    resource_type_tesim: a_collection_containing_exactly(*attributes[:resource_type]),
                    resource_type_sim: a_collection_containing_exactly(*attributes[:resource_type]),
                    subject_tesim: a_collection_containing_exactly(*attributes[:subject]),
                    subject_sim: a_collection_containing_exactly(*attributes[:subject]))
    end
  end
end

RSpec.shared_examples 'a Work indexer' do
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    # NOTE: resource must be persisted for permission tests to pass
    raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::Work' unless defined?(resource) && resource.kind_of?(Hyrax::Work)
    # optionally can pass in default_visibility by setting it with a let statement if your application changes the default; Hyrax defines this as 'restricted'
    # See samvera/hyrda-head hydra-access-controls/app/models/concerns/hydra/access_controls/access_rights.rb for possible VISIBILITY_TEXT_VALUE_...'
  end
  subject(:indexer) { indexer_class.new(resource: resource) }

  it_behaves_like 'a Hyrax::Resource indexer'
  it_behaves_like 'a Core metadata indexer'
  it_behaves_like 'a permission indexer'
  it_behaves_like 'a visibility indexer'
end

RSpec.shared_examples 'a Collection indexer' do
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    # NOTE: resource must be persisted for permission tests to pass
    raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::PcdmCollection' unless defined?(resource) && resource.kind_of?(Hyrax::PcdmCollection)
  end
  subject(:indexer) { indexer_class.new(resource: resource) }

  it_behaves_like 'a Hyrax::Resource indexer'
  it_behaves_like 'a Core metadata indexer'
  it_behaves_like 'a permission indexer'
  it_behaves_like 'a visibility indexer'

  describe '#to_solr' do
    it 'indexes collection type gid' do
      expect(indexer.to_solr)
        .to include(collection_type_gid_ssim: a_collection_containing_exactly(an_instance_of(String)))
    end

    it 'indexes generic type' do
      expect(indexer.to_solr)
        .to include(generic_type_sim: a_collection_containing_exactly('Collection'))
    end

    it 'indexes thumbnail' do
      expect(indexer.to_solr)
        .to include(thumbnail_path_ss: include('assets/collection', '.png'))
    end
  end
end
