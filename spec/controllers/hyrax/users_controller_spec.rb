RSpec.describe Hyrax::UsersController, type: :controller do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "#show" do
    it "show the user profile if user exists" do
      get :show, params: { id: user.user_key }
      expect(response).to be_success
      expect(assigns[:presenter]).to be_kind_of Hyrax::UserProfilePresenter
    end

    it "redirects to root if user does not exist" do
      get :show, params: { id: 'johndoe666' }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("User does not exist")
    end
  end

  describe "#index" do
    let!(:u1) { create(:user) }
    let!(:u2) { create(:user) }

    before do
      allow(Flipflop).to receive(:hide_users_list?).and_return(false)
    end

    describe "requesting html" do
      before do
        # These user types are excluded:
        User.audit_user
        User.batch_user
        create(:user, :guest)
      end

      it "excludes the audit_user and batch_user" do
        get :index
        expect(assigns[:users].to_a).to match_array [user, u1, u2]
        expect(response).to be_successful
      end

      it "sorts by the user key when login is specified" do
        get :index, params: { sort: 'login' }
        expect(assigns[:users].to_a).to match_array [user, u1, u2]
      end

      it "sorts by the user key when login desc is specified" do
        get :index, params: { sort: 'login desc' }
        expect(assigns[:users].to_a).to match_array [user, u1, u2]
      end
    end

    describe "requesting json" do
      render_views

      it "displays users" do
        get :index, params: { format: :json }
        expect(response).to be_successful
        json = JSON.parse(response.body).fetch('users')
        expect(json.map { |u| u['id'] }).to include(u1.id, u2.id)
        expect(json.map { |u| u['text'] }).to include(u1.email, u2.email)
      end
    end

    describe "query users" do
      it "finds the expected user via email" do
        get :index, params: { uq: u1.email }
        expect(assigns[:users]).to include(u1)
        expect(assigns[:users]).not_to include(u2)
        expect(response).to be_successful
      end

      context "by display name" do
        let!(:u1) { create(:user, display_name: "Dr. Curator") }
        let!(:u2) { create(:user, display_name: "Jr. Architect") }

        it "finds the expected user via display name" do
          #
          # allow_any_instance_of(User).to receive(:display_name).and_return("Dr. Curator", "Jr.Archivist")
          get :index, params: { uq: u1.display_name }
          expect(assigns[:users]).to include(u1)
          expect(assigns[:users]).not_to include(u2)
          expect(response).to be_successful
        end
      end

      it "uses the base query with hash as where clause" do
        u3 = create(:user)
        allow(controller).to receive(:base_query).and_return(Hydra.config.user_key_field => u3.email)
        get :index
        expect(assigns[:users]).to include(u3)
        expect(assigns[:users]).not_to include(u1, u2)
        u3.destroy
      end
    end
  end

  describe 'user list access' do
    context 'with hide_users_list?=enabled' do
      before do
        allow(Flipflop).to receive(:hide_users_list?).and_return(true)
      end

      describe 'with registered user' do
        it 'renders the user list' do
          get :index
          expect(response.code).to eq '200'
          expect(response).to render_template(:index)
        end

        it 'does return .json results' do
          get :index, params: { format: :json }
          expect(response).to be_successful
        end
      end

      describe 'with unauthenticated user' do
        before do
          sign_out user
        end

        it 'does not render the user list' do
          get :index
          expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
          expect(response).to have_http_status(302)
          expect(response).to redirect_to('/users/sign_in')
        end

        it 'does not return .json results' do
          get :index, params: { format: :json }
          expect(response).not_to be_successful
        end
      end
    end

    context 'with hide_users_list?=disabled' do
      before do
        sign_out user
        allow(Flipflop).to receive(:hide_users_list?).and_return(false)
      end

      describe 'with unauthenticated user' do
        it 'renders the user list' do
          get :index
          expect(response.code).to eq '200'
          expect(response).to render_template(:index)
        end
      end
    end
  end
end
