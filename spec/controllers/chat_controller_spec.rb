require 'rails_helper'

RSpec.describe Api::V1::ChatsController, type: :controller do
  let!(:application) { Application.create(name: 'Test App') }

  describe 'POST #create' do
  let(:application) { Application.create(token: 'test_token') }

  before do
    allow(Application).to receive(:find_by).with(token: 'test_token').and_return(application)
    allow($redis).to receive(:incr).and_return(1)
    allow($redis).to receive(:rpush)
    allow(ChatCreationJob).to receive(:perform_async)
  end

  context 'with a valid application token' do
    it 'increments the chat counter in Redis' do
      expect($redis).to receive(:incr).with("application:test_token:chat_counter").and_return(1)
      post :create, params: { application_token: 'test_token' }
    end

    it 'pushes chat data to Redis' do
      expect($redis).to receive(:rpush).with("application:test_token:chats", { application_id: application.id, number: 1 }.to_json)
      post :create, params: { application_token: 'test_token' }
    end

    it 'enqueues a ChatCreationJob' do
      expect(ChatCreationJob).to receive(:perform_async).with(application.id)
      post :create, params: { application_token: 'test_token' }
    end

    it 'responds with the chat number and accepted status' do
      post :create, params: { application_token: 'test_token' }
      expect(response).to have_http_status(:accepted)
      expect(JSON.parse(response.body)).to eq({ 'number' => 1 })
    end
  end

  context 'with an invalid application token' do
    before do
      allow(Application).to receive(:find_by).with(token: 'invalid_token').and_return(nil)
    end

    it 'responds with not found status and error message' do
      post :create, params: { application_token: 'invalid_token' }
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq({ 'error' => 'Application not found' })
      end
    end
  end

  describe 'GET #index' do
    let!(:chat1) { Chat.create(application: application, number: 1) }
    let!(:chat2) { Chat.create(application: application, number: 2) }

    context 'when the application exists' do
      it 'returns a JSON response with all chats' do
        get :index, params: { application_token: application.token }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).size).to eq(2)
        expect(JSON.parse(response.body)).to include(
          { 'number' => 1, 'messages_count' => 0 },
          { 'number' => 2, 'messages_count' => 0 }
        )
      end
    end

    context 'when the application does not exist' do
      it 'returns a not found error' do
        get :index, params: { application_token: 'nonexistent_token' }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error' => 'Application not found')
      end
    end
  end

  describe 'GET #show' do
    let!(:chat) { Chat.create(application: application, number: 1) }

    context 'when the application and chat exist' do
      it 'returns a JSON response with the chat details' do
        get :show, params: { application_token: application.token, number: chat.number }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include(
          'number' => 1,
          'messages_count' => 0
        )
      end
    end

    context 'when the application does not exist' do
      it 'returns a not found error' do
        get :show, params: { application_token: 'nonexistent_token', number: chat.number }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error' => 'Application not found')
      end
    end

    context 'when the chat does not exist' do
      it 'returns a not found error' do
        get :show, params: { application_token: application.token, number: 999 }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error' => 'Chat not found')
      end
    end
  end
end