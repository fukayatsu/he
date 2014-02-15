require 'sinatra'
require 'aws-sdk'

set queue: AWS::SQS.new(
  access_key_id:     ENV['AWS_ID'],
  secret_access_key: ENV['AWS_SECRET'],
  region:            ENV['AWS_REGION']
).queues[ENV['SQS_URL']]

use Rack::Auth::Basic, "Restricted Area" do |username, password|
  username == ENV["USERNAME"] and password == ENV["PASSWORD"]
end

get '/' do
  erb :index
end

post '/remote' do
  message = params['command']
  settings.queue.send_message(message)
  'ok'
end