require "spec_helper"

RSpec.describe 'PowerConverter' do
  context '#convert_to_sipity_entity' do
    subject { PowerConverter.convert_to_sipity_entity(object) }

    context "with a Sipity::Entity" do
      let(:object) { Sipity::Entity.new }

      it { is_expected.to eq object }
    end

    context "with a Sipity::Comment" do
      let(:object) { Sipity::Comment.new(entity: entity) }
      let(:entity) { Sipity::Entity.new }

      it { is_expected.to eq entity }
    end

    context "with a SolrDocument" do
      subject { PowerConverter.convert(object, to: :sipity_entity) }

      let(:object) { SolrDocument.new(id: '9999', has_model_ssim: ["GenericWork"]) }
      let(:workflow_state) { create(:workflow_state) }
      let!(:entity) do
        Sipity::Entity.create(proxy_for_global_id: "gid://#{GlobalID.app}/GenericWork/9999",
                              workflow_state: workflow_state,
                              workflow: workflow_state.workflow)
      end

      it { is_expected.to eq entity }
    end

    context 'a Models::Work (because it will be processed)' do
      # This is poking knowledge over into the inner workings of Models::Work
      # but is a reasonable place to understand this.
      it 'will raise an exception if one has not been assigned' do
        object = build(:generic_work)
        expect { PowerConverter.convert_to_sipity_entity(object) }.to raise_error RuntimeError, "Can't create an entity until the model has been persisted"
      end
    end

    it 'will return the to_processing_entity if the object responds to the processing entity' do
      object = double(to_sipity_entity: :processing_entity)
      expect(PowerConverter.convert_to_sipity_entity(object)).to eq(:processing_entity)
    end

    it 'will raise an error if it cannot convert' do
      object = double
      expect { PowerConverter.convert_to_sipity_entity(object) }.to raise_error PowerConverter::ConversionError
    end
  end
end
