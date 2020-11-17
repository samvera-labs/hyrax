# frozen_string_literal: true

RSpec.describe Hyrax::Forms::ResourceForm do
  subject(:form) { described_class.for(work) }
  let(:work)     { Hyrax::Work.new }

  describe '.required_fields=' do
    subject(:form) { form_class.new(work) }

    let(:form_class) do
      Class.new(Hyrax::Forms::ResourceForm(work.class)) do
        property :depositor
      end
    end

    it 'lists required fields' do
      expect(form_class.required_fields).to contain_exactly :title
    end

    it 'can add required fields' do
      expect { form_class.required_fields += [:depositor] }
        .to change { form.required?(:depositor) && form.required?(:title) }
        .to true
    end
  end

  describe '.model_class' do
    it 'is the class of the configured work' do
      expect(Hyrax::Forms::ResourceForm(work.class).model_class)
        .to eq work.class
    end
  end

  describe '#[]' do
    it 'supports access to work attributes' do
      expect(form[:title]).to eq work.title
    end

    it 'gives nil for unsupported attributes' do
      expect(form[:not_a_real_attribute]).to be_nil
    end
  end

  describe '#[]=' do
    it 'supports setting work attributes' do
      new_title = 'comet in moominland'

      expect { form[:title] = new_title }
        .to change { form[:title] }
        .to new_title
    end
  end

  describe '#admin_set_id' do
    it 'is nil' do
      expect(form.admin_set_id).to be_nil
    end

    it 'prepopulates to the default admin set' do
      expect { form.prepopulate! }
        .to change { form.admin_set_id }
        .to AdminSet::DEFAULT_ID
    end
  end

  describe '#agreement_accepted' do
    it { is_expected.to have_attributes(agreement_accepted: false) }

    it 'remains false when prepopulated' do
      expect { form.prepopulate! }
        .not_to change { form.agreement_accepted }
        .from false
    end

    context 'when the work already exists' do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

      it 'prepopulates to true' do
        expect { form.prepopulate! }
          .to change { form.agreement_accepted }
          .to true
      end
    end
  end

  describe '#embargo_release_date' do
    context 'without an embargo' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.embargo_release_date }
          .from(nil)
      end
    end

    context 'with a work under embargo' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_embargo) }

      it 'defaults to the embargo date' do
        expect { form.prepopulate! }
          .to change { form.embargo_release_date }
          .to(work.embargo.embargo_release_date)
      end
    end
  end

  describe '#lease_expiration_date' do
    context 'without a lease' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.lease_expiration_date }
          .from(nil)
      end
    end

    context 'with a work under embargo' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_lease) }

      it 'defaults to the embargo date' do
        expect { form.prepopulate! }
          .to change { form.lease_expiration_date }
          .to(work.lease.lease_expiration_date)
      end
    end
  end

  describe '#member_ids' do
    it 'for a new object has empty membership' do
      expect(form.member_ids).to be_empty
    end

    it 'casts to an array' do
      expect { form.validate(member_ids: '123') }
        .to change { form.member_ids }
        .to contain_exactly('123')
    end

    context 'when the object has members' do
      let(:work) { FactoryBot.build(:monograph, :with_member_works) }

      it 'gives member work ids' do
        expect(form.member_ids).to contain_exactly(*work.member_ids.map(&:id))
      end
    end
  end

  describe '#model_class' do
    it 'is the class of the model' do
      expect(form.model_class).to eq work.class
    end
  end

  describe '#permissions' do
    it 'for a new object has empty permissions' do
      expect(form.permissions).to be_empty
    end

    it 'for a new object prepopulates with empty permissions' do
      expect { form.prepopulate! }
        .not_to change { form.permissions }
        .from(be_empty)
    end

    context 'with existing permissions' do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :public) }

      it 'prepopulates with the work permissions' do
        expect { form.prepopulate! }
          .to change { form.permissions }
          .to contain_exactly(have_attributes(agent_name: 'group/public', access: :read))
      end
    end

    context 'with updated permissions' do
      before do
        form.permissions = { agent_name: 'group/public', access: :read }
      end

      it 'updates the work' do
        expect { form.sync }
          .to change { Hyrax::AccessControl.for(resource: work).permissions }
          .to contain_exactly(have_attributes(agent_name: 'group/public', access: :read))
      end
    end
  end

  describe '#human_readable_type' do
    it 'delegates to model' do
      expect(form.human_readable_type).to eq work.human_readable_type
    end
  end

  describe '#proxy_depositor' do
    let(:user1) { FactoryBot.create(:user).to_s }
    let(:user2) { FactoryBot.create(:user).to_s }
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, on_behalf_of: user2, proxy_depositor: user1) }
    it 'delegates to model' do
      expect(form.proxy_depositor).to eq user1
    end
  end

  describe '#on_behalf_of' do
    let(:user1) { create(:user).to_s }
    let(:user2) { create(:user).to_s }
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, on_behalf_of: user2, proxy_depositor: user1) }
    it 'delegates to model' do
      expect(form.on_behalf_of).to eq user2
    end
  end

  describe '#primary_terms' do
    it 'lists the core metadata primary terms' do
      expect(form.primary_terms).to contain_exactly(:title)
    end

    context 'with custom primary terms' do
      subject(:form) { form_class.new(work) }

      let(:form_class) do
        Class.new(Hyrax::Forms::ResourceForm(work.class)) do
          property :my_primary, virtual: true, primary: true
        end
      end

      it 'adds the custom primary terms' do
        expect(form.primary_terms).to contain_exactly(:title, :my_primary)
      end
    end

    context 'with basic metadata' do
      subject(:form) { form_class.new(work) }

      let(:work) { build(:monograph) }

      let(:form_class) do
        Class.new(Hyrax::Forms::ResourceForm(work.class)) do
          include Hyrax::FormFields(:basic_metadata)
        end
      end

      it 'adds the basic metadata primary terms' do
        expect(form.primary_terms)
          .to contain_exactly(:title, :creator, :rights_statement)
      end
    end
  end

  describe '#required?' do
    subject(:form) { form_class.new(work) }

    let(:form_class) do
      Class.new(Hyrax::Forms::ResourceForm(work.class)) do
        property :non_required, virtual: true
      end
    end

    it 'is true for required fields' do
      expect(form.required?(:title)).to eq true
    end

    it 'is false for non-required fields' do
      expect(form.required?(:non_required)).to eq false
    end
  end

  describe '#secondary_terms' do
    it 'is empty with only core metadata' do
      expect(form.secondary_terms)
        .to be_empty
    end

    context 'with basic metadata' do
      subject(:form) { form_class.new(work) }

      let(:work) { build(:monograph) }

      let(:form_class) do
        Class.new(Hyrax::Forms::ResourceForm(work.class)) do
          include Hyrax::FormFields(:basic_metadata)
        end
      end

      it 'has secondary terms' do
        expect(form.secondary_terms).to include(:description)
      end

      it 'does not have the primary terms' do
        expect(form.secondary_terms)
          .not_to include(:title, :creator, :rights_statement)
      end
    end
  end

  describe '#version' do
    context 'when using wings', valkyrie_adapter: :wings_adapter do
      it 'prepopulates as empty before save' do
        form.prepopulate!
        expect(form.version).to eq ''
      end

      context 'with a saved work' do
        let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

        it 'prepopulates with the etag' do
          af_object = Wings::ActiveFedoraConverter.convert(resource: work)

          form.prepopulate!
          expect(form.version).to eq af_object.etag
        end
      end
    end

    context 'when using a generic valkyrie adapter', valkyrie_adapter: :test_adapter do
      it 'prepopulates as empty before save' do
        form.prepopulate!
        expect(form.version).to eq ''
      end

      context 'with a saved work' do
        let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

        it 'prepopulates empty' do
          form.prepopulate!

          expect(form.version).to eq ''
        end
      end
    end
  end

  describe '#visibility' do
    it 'can set visibility' do
      form.visibility = 'open'

      expect { form.sync }
        .to change { work.permission_manager.acl.permissions }
        .from(be_empty)
        .to contain_exactly(have_attributes(mode: :read, agent: 'group/public'))
    end
  end

  describe '#visibility_after_embargo' do
    context 'without an embargo' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.visibility_after_embargo }
          .from(nil)
      end
    end

    context 'with a work under embargo' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_embargo) }

      it 'defaults to the embargo visibility' do
        expect { form.prepopulate! }
          .to change { form.visibility_after_embargo }
          .from(nil)
          .to('open')
      end
    end
  end

  describe '#visibility_during_embargo' do
    context 'without an embargo' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.visibility_during_embargo }
          .from(nil)
      end
    end

    context 'with a work under embargo' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_embargo) }

      it 'defaults to the embargo visibility' do
        expect { form.prepopulate! }
          .to change { form.visibility_during_embargo }
          .from(nil)
          .to('authenticated')
      end
    end
  end

  describe '#visibility_after_lease' do
    context 'without a lease' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.visibility_after_lease }
          .from(nil)
      end
    end

    context 'with a work under lease' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_lease) }

      it 'defaults to the lease visibility' do
        expect { form.prepopulate! }
          .to change { form.visibility_after_lease }
          .from(nil)
          .to('authenticated')
      end
    end
  end

  describe '#visibility_during_lease' do
    context 'without a lease' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.visibility_during_lease }
          .from(nil)
      end
    end

    context 'with a work under lease' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_lease) }

      it 'defaults to the lease visibility' do
        expect { form.prepopulate! }
          .to change { form.visibility_during_lease }
          .from(nil)
          .to('open')
      end
    end
  end
end
