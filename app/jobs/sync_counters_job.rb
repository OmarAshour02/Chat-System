class SyncCountersJob
    include Sidekiq::Job
  
    def perform
      Application.find_each do |application|
        redis_chat_count = $redis.get("application:#{application.token}:chat_counter").to_i
        application.update_column(:chats_count, redis_chat_count) if redis_chat_count > application.chats_count
  
        application.chats.find_each do |chat|
          redis_message_count = $redis.get("application:#{application.token}:chat:#{chat.number}:message_counter").to_i
          chat.update_column(:messages_count, redis_message_count) if redis_message_count > chat.messages_count
        end
      end
    end
  end