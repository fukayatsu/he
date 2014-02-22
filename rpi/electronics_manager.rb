require 'yaml'
require 'iremocon'
require 'daemon_spawn'
require 'aws-sdk'
require 'dotenv'; Dotenv.load!
require 'active_support/all'

class ElectronicsManager < DaemonSpawn::Base
  def start(args)
    @settings = YAML.load_file('settings.yml')
    @iremocon = Iremocon.new(@settings['iremocon']['address'])

    puts 'start manager'
    loop do
      queue.poll(idle_timeout: 60) do |message|
        ray_number = commands[message.body]
        if ray_number
          @iremocon.is(ray_number)
        else
          puts "[command not found] #{message.body}"
        end
      end

      @iremocon.au # keep alive
    end
  end

  def stop
  end 

private

  def commands
    @settings['iremocon']['commands']
  end

  def queue
    @queue ||= AWS::SQS.new(
      access_key_id:     ENV['AWS_ID'],
      secret_access_key: ENV['AWS_SECRET'],
      region:            ENV['AWS_REGION']
    ).queues[ENV['SQS_URL']]
  end
end

ElectronicsManager.spawn!({
  working_dir: __dir__, 
  pid_file:    File.expand_path(__dir__ + '/tmp/manager.pid'),
  log_file:    File.expand_path(__dir__ + '/log/manager.log'),
  sync_log:    true,
  singleton:   true 
})
