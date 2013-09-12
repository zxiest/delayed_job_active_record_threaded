module Delayed
  class HomeWorker
    DEFAULT_SLEEP_TIME = 0.5
    DEFAULT_MAX_ATTEMPTS = 25
    DEFAULT_TIMEOUT = 60

    attr_accessor :job, :thread, :alive, :sleep_time, :timeout, :max_attempts, :mutex

    def initialize(options=nil)
      @alive =  true

      if (options && options.class == Hash)
        @sleep_time = options[:sleep_time]
        @max_attempts = options[:max_attempts]
        @timeout = options[:timeout]
      end

      @sleep_time ||= DEFAULT_SLEEP_TIME
      @max_attempts ||= DEFAULT_MAX_ATTEMPTS
      @timeout ||= DEFAULT_TIMEOUT
      @mutex = Mutex.new
    end

    def start
      @thread = Thread.new do
        while(@alive)
          begin
            Timeout.timeout(@timeout) do
              work
            end
          # close MySql connection only if exception occurs, keep it alive otherwise
          rescue
            begin
              DelayedJobActiveRecordThreaded.logger.error $!.message if DelayedJobActiveRecordThreaded.logger
              DelayedJobActiveRecordThreaded.logger.error $!.backtrace.join("\n") if DelayedJobActiveRecordThreaded.logger
            rescue
              # logging failed due to IO error?
            end

            unlock @mutex if (@mutex.locked?)

            # free worker from job
            @job = nil

            begin
              # if disconnected
              if (!ActiveRecord::Base.connection || !ActiveRecord::Base.connection.active?)
                # re-establish connection
                ActiveRecord::Base.establish_connection
              end
            rescue
            end
          end

          sleep(@sleep_time)
        end
      end
    end


    def work
      return if !@job

      @mutex.synchronize {
        delayable_type = @job.delayable_type
        delayable_id = @job.delayable_id
        jid = @job.id

        if (@job && @job.respond_to?(:invoke_job))
          t = DateTime.now.to_f
          begin
            @job.invoke_job
            @job.delete
            delta = DateTime.now.to_f - t
          rescue
            if (@job.attempts <= @max_attempts)
              @job.attempts += 1
              @job.run_at = (@job.attempts ** 4 + 5).seconds.from_now
              @job.save
            end
            delta = DateTime.now.to_f - t
          end

          if delayable_type && delayable_id
            DelayedJobActiveRecordThreaded.logger.info "[#{DateTime.now.to_s}] Job for #{delayable_type} delayable_id #{delayable_id} completed in #{delta} seconds" if DelayedJobActiveRecordThreaded.logger
          else
            DelayedJobActiveRecordThreaded.logger.info "[#{DateTime.now.to_s}] Job #{jid} completed in #{delta} seconds" if DelayedJobActiveRecordThreaded.logger
          end

          # done
          @job = nil
        end
      }
    end

    def assign_job(job)
      return if !available?

      @mutex.synchronize {
        @job = job
      }
    end

    def available?
      ret = false

      # the queue can wait a little longer
      # double checking is for performance gains
      if @job.nil?
        @mutex.synchronize {
          if @job.nil?
            ret = @job.nil?
          end
        }
      end
      return ret
    end

    def kill
      @alive = false
    end
  end
end