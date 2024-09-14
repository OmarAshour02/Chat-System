module Api
    module V1
      class ChatsController < ApplicationController

        def create
          @application = Application.find_by(token: params[:application_token])
          if @application
            chat_number = $redis.incr("application:#{@application.token}:chat_counter")

            chat_data = { application_id: @application.id, number: chat_number }

            $redis.rpush("application:#{@application.token}:chats", chat_data.to_json)
            ChatCreationJob.perform_async(@application.id)

            render json: { number: chat_number}, status: :accepted

          else
            render json: { error: 'Application not found' }, status: :not_found
          end
        end
                
        def index
          @application = Application.find_by(token: params[:application_token])
          if @application
            @chats = @application.chats
            render json: @chats.map { |chat| { number: chat.number, messages_count: chat.messages_count } }
          else
            render json: { error: 'Application not found' }, status: :not_found
          end
        end
        
        def show
          @application = Application.find_by(token: params[:application_token])
          if @application
            @chat = @application.chats.find_by(number: params[:number])
            if @chat
              render json: { number: @chat.number, messages_count: @chat.messages_count }
            else
              render json: { error: 'Chat not found' }, status: :not_found
            end
          else
            render json: { error: 'Application not found' }, status: :not_found
          end
        end
      end
    end
  end