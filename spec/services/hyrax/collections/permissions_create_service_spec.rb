# frozen_string_literal: true
RSpec.describe Hyrax::Collections::PermissionsCreateService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }

  describe ".create_default" do
    subject { described_class.create_default(collection: collection, creating_user: user) }

    let(:collection_type) { create(:collection_type) }
    let(:user_manage_attributes) do
      {
        hyrax_collection_type_id: collection_type.id,
        access: 'manage',
        agent_id: user2.user_key,
        agent_type: 'user'
      }
    end
    let(:group_manage_attributes) do
      {
        hyrax_collection_type_id: collection_type.id,
        access: 'manage',
        agent_id: 'manage_group',
        agent_type: 'group'
      }
    end
    let!(:collection_type_participant) { create(:collection_type_participant, user_manage_attributes) }
    let!(:collection_type_participant2) { create(:collection_type_participant, group_manage_attributes) }
    let(:collection) { FactoryBot.build(:collection_lw, id: 'collection1', collection_type: collection_type) }

    before do
      subject
    end

    it "creates the default permission template for the collection" do
      expect(Hyrax::PermissionTemplate.find_by_source_id(collection.id)).to be_persisted
    end

    it "creates the default permission template access entries for the collection" do
      expect(Hyrax::PermissionTemplate.find_by_source_id(collection.id).access_grants.count).to eq 4
    end
  end

  describe ".add_access" do
    subject { described_class.add_access(collection_id: collection.id, grants: grants) }
    let(:collection) { FactoryBot.create(:collection_lw, with_permission_template: true) }
    let(:grants) do
      [{ agent_type: Hyrax::PermissionTemplateAccess::GROUP,
         agent_id: 'archivist',
         access: Hyrax::PermissionTemplateAccess::DEPOSIT }]
    end
    let(:depositor_grants) { collection.permission_template.access_grants.deposit }
    let(:array) { [] }

    before do
      allow(ActiveFedora::Base).to receive(:find).with(collection.id).and_return(collection)
      subject
      depositor_grants.each { |agent| array << agent.agent_id }
    end

    it 'gives deposit access to archivist group' do
      expect(array.include?("archivist")).to eq true
    end
  end
end
