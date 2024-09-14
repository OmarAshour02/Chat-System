class Message < ApplicationRecord
  belongs_to :chat
  validates :number, presence: true, uniqueness: { scope: :chat_id }
  validates :body, presence: true

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'false' do
      indexes :body, analyzer: 'standard'
      indexes :chat_id, type: 'integer'
    end
  end

  def self.search(query, chat_id)
    __elasticsearch__.search(
      query: {
        bool: {
          must: [
            { match_phrase_prefix: { body: query } },
            { term: { chat_id: chat_id } }
          ]
        }
      }
    )
  end
end