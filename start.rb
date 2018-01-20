require 'pg'
require 'pg_csv'
require 'aws-sdk'
require 'dotenv/load'

conn = PG.connect(
  dbname: ENV['POSTGRES_DB'],
  host: ENV['POSTGRES_HOST'],
  port: ENV['POSTGRES_PORT'],
  user: ENV['POSTGRES_USERNAME'],
  password: ENV['POSTGRES_PASSWORD'],
)

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
  config.user_agent = 'InspectorGadget'
end

slack_client = Slack::Web::Client.new
client.auth_test

opts = {
  type: :gzip,
  tmp_file: '/tmp/tmp.csv'
}
filename = '/tmp/foo.gzip'

sql = File.read('health_scores.sql')

PgCsv.new(sql: sql, connection: conn).export(filename, opts)


def send_slack(msg)
  client.chat_postMessage(channel: '#db_sync', text: msg, as_user: true)
end
