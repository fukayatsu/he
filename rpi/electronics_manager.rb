require 'yaml'
require 'iremocon'

class ElectronicsManager
  def initialize
    @settings = YAML.load_file('settings.yml')
    @iremocon = Iremocon.new(@settings['iremocon']['address'])
  end

  def start
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
