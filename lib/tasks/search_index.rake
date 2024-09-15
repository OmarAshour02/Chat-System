namespace :search do
    desc "Reindex all records into Elasticsearch"
    task reindex: :environment do
      puts "Reindexing Elasticsearch..."
      Message.import(force: true)
      puts "Reindexing complete."
    end
  end
  