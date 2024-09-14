module Api
    module V1
      class ApplicationsController < ApplicationController
        
        def create
          @application = Application.new(application_params)
          if @application.save
            render json: { token: @application.token, name: @application.name }, status: :created
          else
            render json: @application.errors, status: :unprocessable_entity
          end
        end
  
        def show
          @application = Application.find_by(token: params[:token])
          if @application
            render json: { token: @application.token, name: @application.name, chats_count: @application.chats_count }
          else
            render json: { error: 'Application not found' }, status: :not_found
          end
        end
  
        def update
          @application = Application.find_by(token: params[:token])
          if @application
            if @application.update(application_params)
              render json: { token: @application.token, name: @application.name }
            else
              render json: @application.errors, status: :unprocessable_entity
            end
          else
            render json: { error: 'Application not found' }, status: :not_found
          end
        end
  
        private
  
        def application_params
          params.require(:application).permit(:name)
        end
      end
    end
  end