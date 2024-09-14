module Api
    module V1
      class MessagesController < ApplicationController

        def create
          @application = Application.find_by(token: params[:application_token])
          if @application
            @chat = @application.chats.find_by(number: params[:chat_number])

            if @chat
              message_number = $redis.incr("chat:#{@chat.id}:message_counter")
              message_data = {
                chat_id: @chat.id,
                number: message_number,
                body: params[:body]
              }
              
              $redis.rpush("chat:#{@chat.id}:messages", message_data.to_json)
              MessageCreationJob.perform_async(@chat.id)
        
              render json: { number: message_number, body: params[:body] }, status: :accepted
            else
              render json: { error: 'Chat not found' }, status: :not_found
            end
          else
            render json: { error: 'Application not found' }, status: :not_found
          end
        end

        def index
          @application = Application.find_by(token: params[:application_token])
          if @application
            @chat = @application.chats.find_by(number: params[:chat_number])
            if @chat
              @messages = @chat.messages
              render json: @messages.map { |message| { number: message.number, body: message.body } }
            else
              render json: { error: 'Chat not found' }, status: :not_found
            end
          else
            render json: { error: 'Application not found' }, status: :not_found
          end
        end
  
        def search
          @application = Application.find_by(token: params[:application_token])
          if @application
            @chat = @application.chats.find_by(number: params[:chat_number])
            if @chat
              results = Message.search(params[:query], @chat.id).records
              render json: results.map { |message| { number: message.number, body: message.body } }
            else
              render json: { error: 'Chat not found' }, status: :not_found
            end
          else
            render json: { error: 'Application not found' }, status: :not_found
          end
        end
  
        private
  
        def message_params
          params.require(:message).permit(:body)
        end
  
        def search_params
          params.permit(:query)
        end
  
      end
    end
  end
  