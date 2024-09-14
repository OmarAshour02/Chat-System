class Chat < ApplicationRecord
  belongs_to :application
  has_many :messages
  validates :number, presence: true, uniqueness: { scope: :application_id }
  attribute :messages_count, :integer, default: 0

end