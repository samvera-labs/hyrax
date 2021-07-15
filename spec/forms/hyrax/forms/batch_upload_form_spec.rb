# frozen_string_literal: true
RSpec.describe Hyrax::Forms::BatchUploadForm do
  let(:model) { GenericWork.new }
  let(:controller) { instance_double(Hyrax::BatchUploadsController) }
  let(:form) { described_class.new(model, ability, controller) }
  let(:ability) { Ability.new(user) }
  let(:user) { build(:user, display_name: 'Jill Z. User') }

  describe "#primary_terms" do
    subject { form.primary_terms }

    it { is_expected.to eq [:creator, :rights_statement] }
    it { is_expected.not_to include(:title) }
  end

  describe "#secondary_terms" do
    subject { form.secondary_terms }

    it { is_expected.not_to include(:title) } # title is per file, not per form
  end

  describe ".model_name" do
    subject { described_class.model_name }

    it "has a route_key" do
      expect(subject.route_key).to eq 'batch_uploads'
    end
    it "has a param_key" do
      expect(subject.param_key).to eq 'batch_upload_item'
    end
  end

  describe "#to_model" do
    subject { form.to_model }

    it "returns itself" do
      expect(subject.to_model).to be_kind_of described_class
    end
  end

  describe "#terms" do
    subject { form.terms }

    it do
      is_expected.to match_array [:alternative_title,
                                  :creator,
                                  :contributor,
                                  :description,
                                  :abstract,
                                  :keyword,
                                  :license,
                                  :rights_statement,
                                  :access_right,
                                  :rights_notes,
                                  :publisher,
                                  :date_created,
                                  :subject,
                                  :language,
                                  :identifier,
                                  :based_near,
                                  :related_url,
                                  :representative_id,
                                  :thumbnail_id,
                                  :rendering_ids,
                                  :files,
                                  :visibility_during_embargo,
                                  :embargo_release_date,
                                  :visibility_after_embargo,
                                  :visibility_during_lease,
                                  :lease_expiration_date,
                                  :visibility_after_lease,
                                  :visibility,
                                  :ordered_member_ids,
                                  :source,
                                  :in_works_ids,
                                  :member_of_collection_ids,
                                  :admin_set_id]
    end
  end
end
