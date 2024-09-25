require 'rails_helper'

RSpec.describe Message, type: :model do
  let(:application) { Application.create(name: "Test App") }
  let(:chat) { Chat.create(application: application, number: 1) }

  describe "associations" do
    it { should belong_to(:chat) }
  end

  describe "validations" do
    subject { Message.new(chat: chat, number: 1, body: "Test message") }

    it { should validate_presence_of(:number) }
    it { should validate_uniqueness_of(:number).scoped_to(:chat_id) }
    it { should validate_presence_of(:body) }
  end

  describe "creation" do
    it "can be created with valid attributes" do
      message = Message.new(chat: chat, number: 1, body: "Test message")
      expect(message).to be_valid
    end

    it "cannot be created without a chat" do
      message = Message.new(number: 1, body: "Test message")
      expect(message).to be_invalid
    end

    it "cannot be created without a number" do
      message = Message.new(chat: chat, body: "Test message")
      expect(message).to be_invalid
    end

    it "cannot be created without a body" do
      message = Message.new(chat: chat, number: 1)
      expect(message).to be_invalid
    end

    it "cannot have duplicate numbers within the same chat" do
      Message.create(chat: chat, number: 1, body: "First message")
      duplicate_message = Message.new(chat: chat, number: 1, body: "Second message")
      expect(duplicate_message).to be_invalid
    end

    it "can have the same number in different chats" do
      other_chat = Chat.create(application: application, number: 2)
      Message.create(chat: chat, number: 1, body: "First message")
      message = Message.new(chat: other_chat, number: 1, body: "Second message")
      expect(message).to be_valid
    end
  end

  describe "Elasticsearch" do
    it "includes Elasticsearch modules" do
      expect(Message.ancestors).to include(Elasticsearch::Model)
      expect(Message.ancestors).to include(Elasticsearch::Model::Callbacks)
    end

    it "defines index settings" do
      settings = Message.settings.to_hash
      expect(settings[:index][:number_of_shards]).to eq(1)
    end

    it "defines mappings" do
      mappings = Message.mappings.to_hash
      expect(mappings[:properties][:body][:analyzer]).to eq('standard')
      expect(mappings[:properties][:chat_id][:type]).to eq('integer')
    end
  end

  describe ".search" do
    let(:mock_response) { double("Elasticsearch::Model::Response::Response") }

    before do
      allow(Message.__elasticsearch__).to receive(:search).and_return(mock_response)
    end

    it "performs a search with the correct query" do
      expected_query = {
        query: {
          bool: {
            must: [
              { match_phrase_prefix: { body: "test query" } },
              { term: { chat_id: chat.id } }
            ]
          }
        }
      }

      expect(Message.__elasticsearch__).to receive(:search).with(expected_query)
      Message.search("test query", chat.id)
    end

    it "returns the Elasticsearch response" do
      result = Message.search("test query", chat.id)
      expect(result).to eq(mock_response)
    end
  end
end