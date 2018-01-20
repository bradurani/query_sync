VERSION = 0.1

require 'pg'
require 'pg_csv'
require 'aws-sdk'
require 'dotenv/load'


def run_query(sql, filename)
  send_slack("Running query and saving to #{filename}")
  PgCsv.new(sql: sql, connection: @conn).export(filename, {
    type: :gzip,
  })
  send_slack("Finished Query")
end


def send_slack(msg)
  if @slack_client
    @slack_client.chat_postMessage(channel: '#deep-sink', text: msg, as_user: true)
  end
end

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
    dbname: ENV['POSTGRES_DB'],
    host: ENV['POSTGRES_HOST'],
    port: ENV['POSTGRES_PORT'],
    user: ENV['POSTGRES_USERNAME'],
    password: ENV['POSTGRES_PASSWORD'],
  )
end

def query
  File.read('health_scores.sql')
end

def start(query, filename)
  File.delete(filename)
  run_query(query, filename)
rescue => e
  send_slack(e.message)
end

filename = '/tmp/health_score_query_results.gzip'
@conn = configure_postgres_connection
@slack_client = configure_slack_client

start(query, filename)


