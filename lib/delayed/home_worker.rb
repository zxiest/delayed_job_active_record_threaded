require 'timeout'
require 'celluloid'

module Delayed
  class HomeWorker
    include Celluloid

    DEFAULT_MAX_ATTEMPTS = 25
    DEFAULT_TIMEOUT = 60

    attr_accessor :timeout, :max_attempts

    def initialize(options=nil)
      if (options && options.class == Hash)
        @max_attempts = options[:max_attempts]
        @timeout = options[:timeout]
      end

      @max_attempts ||= DEFAULT_MAX_ATTEMPTS
      @timeout ||= DEFAULT_TIMEOUT
    end

    def work(job)
      delayable_type = job.delayable_type
      delayable_id = job.delayable_id
      jid = job.id

      t = DateTime.now.to_f
      if (job && job.respond_to?(:invoke_job))
        begin
          Timeout.timeout(@timeout) do
            job.invoke_job
            job.delete
          end
        rescue
          if (job.attempts <= @max_attempts)
            job.attempts += 1
            job.run_at = (job.attempts ** 4 + 5).seconds.from_now
            job.save
          end
        end

        delta = DateTime.now.to_f - t

        if delayable_type && delayable_id
          DelayedJobActiveRecordThreaded.logger.info "[#{DateTime.now.to_s}] Job for #{delayable_type} delayable_id #{delayable_id} completed in #{delta} seconds" if DelayedJobActiveRecordThreaded.logger
        else
          DelayedJobActiveRecordThreaded.logger.info "[#{DateTime.now.to_s}] Job #{jid} completed in #{delta} seconds" if DelayedJobActiveRecordThreaded.logger
        end
      end

    ensure
      #attempt closing connection
      begin
        if (ActiveRecord::Base.connection && ActiveRecord::Base.connection.active?)
          ActiveRecord::Base.connection.close
        end
      rescue
      end
    end
  end
end