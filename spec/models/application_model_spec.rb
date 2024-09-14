require 'rails_helper'

RSpec.describe Application, type: :model do
  it { should have_many(:chats) }

  it { should validate_presence_of(:name) }

  describe 'callbacks' do
    it 'generates a token before creating the record' do
      application = Application.create(name: 'Test Application')
      expect(application.token).to be_present
    end
  end

  describe 'attributes' do
    it 'has a default chats_count value of 0' do
      application = Application.new(name: 'Test Application')
      expect(application.chats_count).to eq(0)
    end
  end
end
