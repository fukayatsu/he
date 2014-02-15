#!/usr/bin/env ruby

require 'google/api_client'
require 'aws-sdk'
require 'dotenv'; Dotenv.load!
require 'active_support/all'

class CalendarWatcher
  # run every 5 minutes by cron
  def run
    puts "fetching calendar..."
    time_range = Time.now.ago(2.minutes)..Time.now.since(3.minutes)
    events = fetch_events(range: time_range)

    commands = {}
    events.each do |event|
      device, command = event.summary.split(':')
      if time_range.cover?(event.start.date_time)
        commands[device] = command
      elsif time_range.cover?(event.end.date_time)
        commands[device] ||= 'off'
      end
    end

    commands.each do |device, command|
      message = "#{device}:#{command}"
      queue.send_message(message)
      puts "[queued]#{message}"
    end
  end

private

  def queue
    @queue ||= AWS::SQS.new(
      access_key_id:     ENV['AWS_ID'],
      secret_access_key: ENV['AWS_SECRET'],
      region:            ENV['AWS_REGION']
    ).queues[ENV['SQS_URL']]
  end

  def calendar_client
    return @calendar_client if @calendar_client

    client = Google::APIClient.new(
      application_name: 'fukayatsu HE',
      application_version: '0.0.1'
    )
    client.authorization.client_id     = ENV['GOOGLE_CLIENT_ID']
    client.authorization.client_secret = ENV['GOOGLE_CLIENT_SECRET']
    client.authorization.access_token  = ENV['G_CAL_ACCESS_TOKEN']
    client.authorization.refresh_token = ENV['G_CAL_REFRESH_TOKEN']
    client.authorization.scope         = ['https://www.googleapis.com/auth/calendar']
    client.authorization.fetch_access_token!
    @calendar_client = client
  end

  def fetch_events(range: Time.now..Time.now.since(1.day))
    calendar_api = calendar_client.discovered_api('calendar', 'v3')
    params = {
      "calendarId" => ENV['G_CAL_ID'],
      "timeMin"    => range.begin.utc.iso8601,
      "timeMax"    => range.end.utc.iso8601,
    }
    result = calendar_client.execute(
      :api_method => calendar_api.events.list,
      :parameters => params
    )
    result.data.items
  end
end

# CalendarWatcher.new.run