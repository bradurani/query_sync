VERSION = 0.1

require 'pg'
require 'pg_csv'
require 'aws-sdk-s3'
require 'dotenv/load'

def configure_slack_client
  if slack_token = ENV['SLACK_API_TOKEN']
    Slack.configure do |config|
      config.token = slack_token
      config.user_agent = "query_sync/#{VERSION}"
    end

    client = Slack::Web::Client.new
    client.auth_test
    client
  end
end

def configure_postgres_connection
  PG.connect(
    dbname: ENV.fetch('POSTGRES_DB'),
    host: ENV.fetch('POSTGRES_HOST'),
    port: ENV.fetch('POSTGRES_PORT', 5432),
    user: ENV.fetch('POSTGRES_USERNAME'),
    password: ENV.fetch('POSTGRES_PASSWORD'),
  )
end

def query
  File.read('health_scores.sql')
end

def send_slack(msg)
  if @slack_client
    @slack_client.chat_postMessage(channel: '#deep-sink', text: msg, as_user: true)
  else
    puts msg
  end
end

def run_query(sql, filename)
  send_slack("Running query and saving to #{filename}")
  PgCsv.new(sql: sql, connection: @conn).export(filename, {
    type: :gzip,
  })
  send_slack("Finished query")
end

def upload_file(filename)
  bucket = ENV.fetch('AWS_S3_BUCKET')
  send_slack("starting upload #{filename} to #{bucket}")
  s3 = Aws::S3::Resource.new
  obj = s3.bucket(bucket).object(filename)
  obj.upload_file(filename)
  send_slack("finished uploading #{filename}")
end

def start(query, filename)
  send_slack('Starting...')
  File.delete(filename)
  run_query(query, filename)
  upload_file(filename)
  send_slack('Finished 🚰')
rescue => e
  send_slack(e.message)
  raise
end

filename = '/tmp/health_score_query_results.gzip'
@conn = configure_postgres_connection
@slack_client = configure_slack_client

start(query, filename)


