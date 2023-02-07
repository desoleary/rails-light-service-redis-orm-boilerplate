require 'rails_helper'

describe ApplicationValidatorAction do
  let(:action_class) do
    Class.new(ApplicationValidatorAction) do
      self.contract_class = Class.new(ApplicationContract) do
        params { required(:key).filled(:string) }
      end
    end
  end

  let(:value) { 'some-value' }
  let(:input) { { key: value } }
  let(:ctx) { ApplicationContext.make_with_defaults(input) }

  subject { action_class.execute(ctx) }

  context 'with valid attributes' do
    it 'returns promised params and empty errors' do
      expect(subject.success?).to be(true)
      expect(subject.errors).to be_empty
      expect(subject[:params].keys).to eql(%i[key])
    end
  end

  context 'with invalid attributes' do
    let(:value) { nil }

    it 'returns promised params and filled in errors' do
      expect(subject.failure?).to be_truthy
      expect(subject.errors).to eql(key: 'must be filled')
    end
  end
end
