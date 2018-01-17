RSpec.describe FeaturedWorkList, type: :model do
  let(:work1) { create_for_repository(:work) }
  let(:work2) { create_for_repository(:work) }
  let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }

  describe 'featured_works' do
    before do
      create(:featured_work, work_id: work1.id)
      create(:featured_work, work_id: work2.id)
    end

    it 'is a list of the featured work objects, each with the generic_work\'s solr_doc' do
      expect(subject.featured_works.size).to eq 2
      presenter = subject.featured_works.first.presenter
      expect(presenter).to be_kind_of Hyrax::WorkShowPresenter
      expect(presenter.id).to eq work1.id.to_s
    end

    context 'when one of the files is deleted' do
      before do
        persister.delete(resource: work1)
      end

      it 'is a list of the remaining featured work objects, each with the generic_work\'s solr_doc' do
        expect(subject.featured_works.size).to eq 1
        presenter = subject.featured_works.first.presenter
        expect(presenter).to be_kind_of Hyrax::WorkShowPresenter
        expect(presenter.id).to eq work2.id.to_s
      end
    end
  end

  describe '#featured_works_attributes=' do
    # We don't need to persist the given work. This saves a few LDP calls.
    let(:work_id) { 'no-need-to-persist' }
    let(:featured_work) { create(:featured_work, work_id: work_id) }

    let(:attributes) do
      ActionController::Parameters.new(
        "0" => {
          "id" => featured_work.id,
          "order" => "5"
        }
      ).permit!
    end
    let(:instance) { described_class.new }

    subject { instance.featured_works_attributes = attributes }

    it "sets order" do
      subject
      expect(featured_work.order).to eq 5
    end
  end

  it { is_expected.to delegate_method(:empty?).to(:featured_works) }
end
