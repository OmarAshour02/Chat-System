Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://redis:6379' }

  config.on(:startup) do
    Sidekiq.schedule = YAML.load_file(File.expand_path('../../sidekiq.yml', __FILE__))
    Sidekiq::Scheduler.reload_schedule!
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://redis:6379' }
end
