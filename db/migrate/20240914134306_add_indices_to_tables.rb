class AddIndicesToTables < ActiveRecord::Migration[7.0]
  def change
    unless index_exists?(:applications, :token, name: 'index_applications_on_token')
      add_index :applications, :token, name: 'index_applications_on_token'
    end

    unless index_exists?(:chats, :application_id, name: 'index_chats_on_application_id')
      add_index :chats, :application_id, name: 'index_chats_on_application_id'
    end

    unless index_exists?(:chats, [:number, :application_id], name: 'index_chats_on_number_and_application_id')
      add_index :chats, [:number, :application_id], name: 'index_chats_on_number_and_application_id'
    end

    unless index_exists?(:messages, :chat_id, name: 'index_messages_on_chat_id')
      add_index :messages, :chat_id, name: 'index_messages_on_chat_id'
    end

    unless index_exists?(:messages, [:number, :chat_id], name: 'index_messages_on_number_and_chat_id')
      add_index :messages, [:number, :chat_id], name: 'index_messages_on_number_and_chat_id'
    end
  end
end
