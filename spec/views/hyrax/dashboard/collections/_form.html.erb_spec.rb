RSpec.describe 'hyrax/dashboard/collections/_form.html.erb', type: :view do
  let(:collection) { Collection.new }
  let(:change_set) { Hyrax::CollectionChangeSet.new(collection) }

  before do
    # allow(collection).to receive(:open_access?).and_return(true)
    # allow(collection).to receive(:authenticated_only_access?).and_return(false)
    # allow(collection).to receive(:private_access?).and_return(false)
    controller.request.path_parameters[:id] = 'j12345'
    assign(:change_set, change_set)
    assign(:collection, collection)
    # Stub route because view specs don't handle engine routes
    allow(view).to receive(:collections_path).and_return("/collections")
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    allow(change_set).to receive(:display_additional_fields?).and_return(additional_fields)
    allow(change_set).to receive(:permissions).and_return([])
  end

  context 'with secondary terms' do
    let(:additional_fields) { true }

    before do
      render
    end
    it "draws the metadata fields for collection" do
      expect(rendered).to have_selector("input#collection_title")
      expect(rendered).to have_selector("span.required-tag", text: "required")
      expect(rendered).not_to have_selector("div#additional_title.multi_value")
      expect(rendered).to have_selector("input#collection_creator.multi_value")
      expect(rendered).to have_selector("textarea#collection_description")
      expect(rendered).to have_selector("input#collection_contributor")
      expect(rendered).to have_selector("input#collection_keyword")
      expect(rendered).to have_selector("input#collection_subject")
      expect(rendered).to have_selector("input#collection_publisher")
      expect(rendered).to have_selector("input#collection_date_created")
      expect(rendered).to have_selector("input#collection_language")
      expect(rendered).to have_selector("input#collection_identifier")
      expect(rendered).to have_selector("input#collection_based_near")
      expect(rendered).to have_selector("input#collection_related_url")
      expect(rendered).to have_selector("select#collection_license")
      expect(rendered).to have_selector("select#collection_resource_type")
      expect(rendered).to have_content('Additional fields')
    end
  end
  context 'with no secondary terms' do
    let(:additional_fields) { false }

    before do
      render
    end
    it 'does not render additional fields button' do
      expect(rendered).not_to have_content('Additional fields')
    end
  end
end
