class ChatCreationJob
    include Sidekiq::Job
  
    def perform(application_id)
    application = Application.find(application_id)
    chat_data = $redis.lpop("application:#{application.token}:chats")

      return if chat_data.nil?
  
      chat_data = JSON.parse(chat_data)
      chat = Chat.create!(application: application, number: chat_data['number'])
      application.increment!(:chats_count)
    end
  end