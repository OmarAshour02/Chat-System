require 'rails_helper'

RSpec.describe Api::V1::ApplicationsController, type: :controller do
  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_params) { { application: { name: 'Test App' } } }

      it 'creates a new application' do
        expect {
          post :create, params: valid_params
        }.to change(Application, :count).by(1)
      end

      it 'returns a JSON response with the new application' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to include('name' => 'Test App')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) { { application: { name: '' } } }

      it 'does not create a new application' do
        expect {
          post :create, params: invalid_params
        }.to_not change(Application, :count)
      end

      it 'returns a JSON response with errors' do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to have_key('name')
      end
    end
  end

  describe 'GET #show' do
    let!(:application) { Application.create(name: 'Test App') }

    context 'when the application exists' do
      it 'returns a JSON response with the application details' do
        get :show, params: { token: application.token }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include(
          'token' => application.token,
          'name' => 'Test App',
          'chats_count' => 0
        )
      end
    end

    context 'when the application does not exist' do
      it 'returns a not found error' do
        get :show, params: { token: 'nonexistent_token' }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error' => 'Application not found')
      end
    end
  end

  describe 'PUT #update' do
    let!(:application) { Application.create(name: 'Test App') }

    context 'with valid parameters' do
      let(:valid_params) { { token: application.token, application: { name: 'Updated App' } } }

      it 'updates the application' do
        put :update, params: valid_params
        application.reload
        expect(application.name).to eq('Updated App')
      end

      it 'returns a JSON response with the updated application' do
        put :update, params: valid_params
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('name' => 'Updated App')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) { { token: application.token, application: { name: '' } } }

      it 'does not update the application' do
        put :update, params: invalid_params
        application.reload
        expect(application.name).to eq('Test App')
      end

      it 'returns a JSON response with errors' do
        put :update, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to have_key('name')
      end
    end

    context 'when the application does not exist' do
      it 'returns a not found error' do
        put :update, params: { token: 'nonexistent_token', application: { name: 'Updated App' } }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error' => 'Application not found')
      end
    end
  end
end