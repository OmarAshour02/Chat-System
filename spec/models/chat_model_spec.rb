require 'rails_helper'

RSpec.describe Chat, type: :model do
  let(:application) { Application.create(name: "Test App") }
  
  describe "associations" do
    it { should belong_to(:application) }
    it { should have_many(:messages) }
  end

  describe "validations" do
    subject { Chat.new(application: application, number: 1) }
    
    it { should validate_presence_of(:number) }
    it { should validate_uniqueness_of(:number).scoped_to(:application_id) }
  end

  describe "attributes" do
    it "has a default value of 0 for messages_count" do
      chat = Chat.new
      expect(chat.messages_count).to eq(0)
    end
  end

  describe "creation" do
    it "can be created with valid attributes" do
      chat = Chat.new(application: application, number: 1)
      expect(chat).to be_valid
    end

    it "cannot be created without an application" do
      chat = Chat.new(number: 1)
      expect(chat).to be_invalid
    end

    it "cannot be created without a number" do
      chat = Chat.new(application: application)
      expect(chat).to be_invalid
    end

    it "cannot have duplicate numbers within the same application" do
      Chat.create(application: application, number: 1)
      duplicate_chat = Chat.new(application: application, number: 1)
      expect(duplicate_chat).to be_invalid
    end

    it "can have the same number in different applications" do
      other_application = Application.create(name: "Other App")
      Chat.create(application: application, number: 1)
      chat = Chat.new(application: other_application, number: 1)
      expect(chat).to be_valid
    end
  end
end