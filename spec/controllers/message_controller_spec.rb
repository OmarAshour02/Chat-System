require 'rails_helper'

RSpec.describe Api::V1::MessagesController, type: :controller do
  let!(:application) { Application.create(name: 'Test App') }
  let!(:chat) { Chat.create(application: application, number: 1) }

  describe 'POST #create' do
    before do
      allow($redis).to receive(:incr).and_return(1)
      allow($redis).to receive(:rpush)
      allow(MessageCreationJob).to receive(:perform_async)
    end

    context 'with a valid application token and chat number' do
      before do
        allow(Application).to receive(:find_by).with(token: 'test_token').and_return(application)
        allow(application.chats).to receive(:find_by).with(number: '1').and_return(chat)
      end

      it 'increments the message counter in Redis' do
        expect($redis).to receive(:incr).with("chat:#{chat.id}:message_counter").and_return(1)
        post :create, params: { application_token: 'test_token', chat_number: '1', body: 'Hello, world!' }
      end

      it 'pushes message data to Redis' do
        expected_message_data = {
          chat_id: chat.id,
          number: 1,
          body: 'Hello, world!'
        }.to_json
        expect($redis).to receive(:rpush).with("chat:#{chat.id}:messages", expected_message_data)
        post :create, params: { application_token: 'test_token', chat_number: '1', body: 'Hello, world!' }
      end

      it 'enqueues a MessageCreationJob' do
        expect(MessageCreationJob).to receive(:perform_async).with(chat.id)
        post :create, params: { application_token: 'test_token', chat_number: '1', body: 'Hello, world!' }
      end

      it 'responds with the message number, body, and accepted status' do
        post :create, params: { application_token: 'test_token', chat_number: '1', body: 'Hello, world!' }
        expect(response).to have_http_status(:accepted)
        expect(JSON.parse(response.body)).to eq({ 'number' => 1, 'body' => 'Hello, world!' })
      end
    end

    context 'with a valid application token but invalid chat number' do
      before do
        allow(Application).to receive(:find_by).with(token: 'test_token').and_return(application)
        allow(application.chats).to receive(:find_by).with(number: '999').and_return(nil)
      end

      it 'responds with not found status and error message' do
        post :create, params: { application_token: 'test_token', chat_number: '999', body: 'Hello, world!' }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Chat not found' })
      end
    end

    context 'with an invalid application token' do
      before do
        allow(Application).to receive(:find_by).with(token: 'invalid_token').and_return(nil)
      end

      it 'responds with not found status and error message' do
        post :create, params: { application_token: 'invalid_token', chat_number: '1', body: 'Hello, world!' }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Application not found' })
      end
    end
  end

  describe 'GET #index' do
    let!(:message1) { Message.create(chat: chat, number: 1, body: 'Message 1') }
    let!(:message2) { Message.create(chat: chat, number: 2, body: 'Message 2') }

    context 'when the application and chat exist' do
      it 'returns a JSON response with all messages' do
        get :index, params: { application_token: application.token, chat_number: chat.number }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).size).to eq(2)
        expect(JSON.parse(response.body)).to include(
          { 'number' => 1, 'body' => 'Message 1' },
          { 'number' => 2, 'body' => 'Message 2' }
        )
      end
    end

    context 'when the application does not exist' do
      it 'returns a not found error' do
        get :index, params: { application_token: 'nonexistent_token', chat_number: chat.number }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error' => 'Application not found')
      end
    end

    context 'when the chat does not exist' do
      it 'returns a not found error' do
        get :index, params: { application_token: application.token, chat_number: 999 }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error' => 'Chat not found')
      end
    end
  end

  describe 'GET #search' do
    let!(:message1) { Message.create(chat: chat, number: 1, body: 'Hello world') }
    let!(:message2) { Message.create(chat: chat, number: 2, body: 'Goodbye world') }

    context 'when the application and chat exist' do
      it 'returns a JSON response with matching messages' do
        allow(Message).to receive(:search).and_return(double(records: [message1]))
        
        get :search, params: { application_token: application.token, chat_number: chat.number, query: 'Hello' }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).size).to eq(1)
        expect(JSON.parse(response.body)).to include(
          { 'number' => 1, 'body' => 'Hello world' }
        )
      end
    end

    context 'when the application does not exist' do
      it 'returns a not found error' do
        get :search, params: { application_token: 'nonexistent_token', chat_number: chat.number, query: 'Hello' }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error' => 'Application not found')
      end
    end

    context 'when the chat does not exist' do
      it 'returns a not found error' do
        get :search, params: { application_token: application.token, chat_number: 999, query: 'Hello' }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error' => 'Chat not found')
      end
    end
  end
end