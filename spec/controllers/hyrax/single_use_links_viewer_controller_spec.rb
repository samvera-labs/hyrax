# frozen_string_literal: true
RSpec.describe Hyrax::SingleUseLinksViewerController do
  routes { Hyrax::Engine.routes }
  let(:user) { build(:user) }
  let(:file) do
    create(:file_set, label: 'world.png', user: user)
  end
  let(:hyrax_file) do
    uploaded_file = fixture_file_upload('/world.png', 'image/png')
    file_set = FactoryBot.valkyrie_create(:hyrax_file_set)
    Hyrax.storage_adapter.upload(resource: file_set, file: uploaded_file, original_filename: "content.txt")
    file_set
  end

  describe "retrieval links" do
    let :show_link do
      SingleUseLink.create item_id: file.id, path: Rails.application.routes.url_helpers.hyrax_file_set_path(id: file, locale: 'en')
    end

    let :download_link do
      Hydra::Works::AddFileToFileSet.call(file, File.open(fixture_path + '/world.png'), :original_file)
      SingleUseLink.create item_id: file.id, path: Hyrax::Engine.routes.url_helpers.download_path(id: file, locale: 'en')
    end

    let :hyrax_download_link do
      SingleUseLink.create item_id: hyrax_file.id, path: Hyrax::Engine.routes.url_helpers.download_path(id: hyrax_file, locale: 'en')
    end

    let(:show_link_hash) { show_link.download_key }
    let(:download_link_hash) { download_link.download_key }

    describe "GET 'download'" do
      context "when valkyrie is false" do
        let(:expected_content) { Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: file.id, use_valkyrie: false).original_file.content }
        it "downloads the file and deletes the link from the database" do
          expect(controller).to receive(:send_file_headers!).with(filename: 'world.png', disposition: 'attachment', type: 'image/png')
          get :download, params: { id: download_link_hash }
          expect(response.body).to eq expected_content
          expect(response).to be_successful
          expect { SingleUseLink.find_by_download_key!(download_link_hash) }.to raise_error ActiveRecord::RecordNotFound
        end
      end
      context "when valkyrie is true" do
        let(:retrieved_file) { Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: hyrax_file.id, use_valkyrie: true) }
        let(:file_metadata) { Hyrax.custom_queries.find_file_metadata_by(id: retrieved_file.file_ids.first.id) }
        it "downloads the file and deletes the link from the database" do
          byebug
          expect(controller).to receive(:send_file_headers!).with(filename: 'world.png', disposition: 'attachment', type: 'image/png')
          get :download, params: { id: download_link_hash }
          expect(response.body).to eq expected_content
          expect(response).to be_successful
          expect { SingleUseLink.find_by_download_key!(download_link_hash) }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context "when the key is not found" do
        before { SingleUseLink.find_by_download_key!(download_link_hash).destroy }

        it "returns 404" do
          get :download, params: { id: download_link_hash }
          expect(response).to render_template("hyrax/single_use_links_viewer/single_use_error", "layouts/error")
        end
      end
    end

    describe "GET 'show'" do
      it "renders the file set's show page and deletes the link from the database" do
        get 'show', params: { id: show_link_hash }
        expect(response).to be_successful
        expect(assigns[:presenter].id).to eq file.id
        expect { SingleUseLink.find_by_download_key!(show_link_hash) }.to raise_error ActiveRecord::RecordNotFound
      end

      context "when the key is not found" do
        before { SingleUseLink.find_by_download_key!(show_link_hash).destroy }
        it "returns 404" do
          get :show, params: { id: show_link_hash }
          expect(response).to render_template("hyrax/single_use_links_viewer/single_use_error", "layouts/error")
        end
      end

      it "returns 404 on attempt to get show path with download hash" do
        get :show, params: { id: download_link_hash }
        expect(response).to render_template("hyrax/single_use_links_viewer/single_use_error", "layouts/error")
      end
    end
  end
end
