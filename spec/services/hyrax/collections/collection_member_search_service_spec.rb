# frozen_string_literal: true
RSpec.describe Hyrax::Collections::CollectionMemberSearchService, clean_repo: true do
  subject(:builder) do
    described_class.new(scope: scope, collection: nestable_collection, params: { "id" => nestable_collection.id.to_s })
  end

  let(:current_ability) { instance_double(Ability, admin?: true) }
  let(:scope) { FakeSearchBuilderScope.new(current_ability: current_ability) }
  let!(:subcollection) { create(:public_collection_lw, member_of_collections: [nestable_collection], collection_type_settings: [:nestable]) }

  let!(:nestable_collection) { create(:public_collection_lw, collection_type_settings: [:nestable]) }
  let!(:work1) { create(:generic_work, member_of_collections: [nestable_collection]) }
  let!(:work2) { create(:generic_work) }
  let!(:work3) { create(:generic_work, member_of_collections: [nestable_collection]) }

  describe '#available_member_subcollections' do
    it 'returns the members that are collections' do
      ids = builder.available_member_subcollections.response[:docs].map { |col| col[:id] }

      expect(ids).to contain_exactly(subcollection.id)
    end
  end

  describe '#available_member_works' do
    it 'returns the members that are collections' do
      ids = builder.available_member_works.response[:docs].map { |col| col[:id] }

      expect(ids).to contain_exactly(work1.id, work3.id)
    end
  end

  describe '#available_member_work_ids' do
    it 'returns the members ids that are works' do
      ids = builder.available_member_work_ids.response[:docs].map { |col| col[:id] }

      expect(ids).to contain_exactly(work1.id, work3.id)
    end
  end
end
