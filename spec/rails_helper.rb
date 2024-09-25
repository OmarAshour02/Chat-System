require 'spec_helper'
require 'sidekiq/testing'
require 'mock_redis'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.before(:each) do
    mock_redis = MockRedis.new
    Sidekiq.configure_client do |sidekiq_config|
      sidekiq_config.redis = { url: 'redis://localhost:6379/0', size: 1 }
    end

    Sidekiq.configure_server do |sidekiq_config|
      sidekiq_config.redis = { url: 'redis://localhost:6379/0', size: 1 }
    end

    allow(Sidekiq).to receive(:redis).and_yield(mock_redis)

    Sidekiq::Testing.fake!
  end

  config.after(:each) do
    Sidekiq::Worker.clear_all
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end