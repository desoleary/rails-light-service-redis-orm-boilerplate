require 'rails_helper'

describe ApplicationAction do
  FakeApplicationAction = Class.new(ApplicationAction) do
    executed do |context|
      value = context.dig(:input, :callback).call
      add_params(context, value: value)
    end
  end

  let(:organizer_class) do
    Class.new(ApplicationOrganizer) do
      def self.steps
        [FakeApplicationAction]
      end
    end
  end

  let(:value) { 'some-value' }
  let(:callback) { -> { value } }
  let(:input) { { callback: callback } }
  let(:ctx) do
    LightService::Testing::ContextFactory.
      make_from(organizer_class).
      for(FakeApplicationAction).
      with(callback: callback)
  end

  subject do
    FakeApplicationAction.execute(ctx)
  end

  it 'adds value returned by callback to params' do
    expect(subject.keys).to include(:input, :errors, :params)

    expect(subject[:params]).to eql({ value: value })
  end
end
