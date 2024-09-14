class MessageCreationJob
    include Sidekiq::Job
  
    def perform(chat_id)
      chat = Chat.find(chat_id)
      message_data = $redis.lpop("chat:#{chat_id}:messages")

      return if message_data.nil?

      message_data = JSON.parse(message_data);  

      message = chat.messages.create(
        number: message_data['number'],
        body: message_data['body']
      )
      
      chat.increment!(:messages_count)
    end
  end