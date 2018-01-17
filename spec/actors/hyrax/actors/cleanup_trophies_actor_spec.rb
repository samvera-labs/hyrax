RSpec.describe Hyrax::Actors::CleanupTrophiesActor do
  let(:ability) { ::Ability.new(depositor) }
  let(:change_set) { GenericWorkChangeSet.new(work) }
  let(:change_set_persister) { double }
  let(:env) { Hyrax::Actors::Environment.new(change_set, change_set_persister, ability, attributes) }
  let(:depositor) { create(:user) }
  let(:work) { create_for_repository(:work) }
  let(:attributes) { {} }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(instance_double(Hyrax::Actors::ModelActor, create: true, update: true, destroy: true))
  end

  describe "#destroy" do
    subject { middleware.destroy(env) }

    let!(:trophy) { Trophy.create(user_id: depositor.id, work_id: work.id) }

    it 'removes all the trophies' do
      expect { middleware.destroy(env) }.to change { Trophy.where(work_id: work.id.to_s).count }.from(1).to(0)
    end
  end
end
