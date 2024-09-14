class Application < ApplicationRecord
    has_many :chats
    validates :name, presence: true
    before_create :generate_token
    attribute :chats_count, :integer, default: 0

    private
  
    def generate_token
      self.token = SecureRandom.hex(16)
    end
    
  end