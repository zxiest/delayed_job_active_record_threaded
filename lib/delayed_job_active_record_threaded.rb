Dir["tasks/**/*.rake"].each { |ext| load ext } if defined?(Rake)

class DelayedJobActiveRecordThreaded
  class << self
    attr_accessor :logger
  end

  # if rails logger exists, use it
  # otherwise, use STDOUT and STDERR
  if defined?(Rails) && Rails.logger
    DelayedJobActiveRecordThreaded.logger = Rails.logger if Rails.logger
  else
    DelayedJobActiveRecordThreaded.logger = Object.new

    def logger.info(str)
      STDOUT.write("#{str}\n");
      nil
    end

    def logger.error(str)
      STDERR.write("#{str}\n");
      nil
    end
  end
end

to_require = %w(home_manager home_worker fake_job job)
to_require.each do |f|
  require "#{File.dirname(__FILE__)}/delayed/#{f}"
end

require "#{File.dirname(__FILE__)}/delayed/railtie" if defined?(Rails)