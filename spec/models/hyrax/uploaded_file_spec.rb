# frozen_string_literal: true
RSpec.describe Hyrax::UploadedFile do
  let(:file1) { File.open(fixture_path + '/world.png') }

  subject { described_class.create(file: file1) }

  it "is not in the public directory" do
    temp_dir = Rails.root + 'tmp'
    expect(subject.file.path).to start_with temp_dir.to_s
  end

  describe '#perform_ingest_later' do
    let(:user) { FactoryBot.create(:user) }
    subject { described_class.create(file: file1, user: user) }
    context 'for a Valkyrie object' do
      it "schedules an IngestJob" do
        file_set = FactoryBot.valkyrie_create(:hyrax_file_set)
        expect(IngestJob).to receive(:perform_later).with(kind_of(JobIoWrapper))
        subject.perform_ingest_later(file_set: file_set)
      end
    end
  end
end
