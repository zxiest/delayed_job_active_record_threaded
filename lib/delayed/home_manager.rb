require 'date_core'

module Delayed
  class HomeManager
    DEFAULT_SLEEP_TIME = 5
    DEFAULT_JOBS_TO_PULL = 20
    DEFAULT_WORKERS_NUMBER = 16
    DEFAULT_WORKER_OPTIONS = {
        :sleep_time => 0.5
    }
    DEFAULT_TIMEOUT = 20

    attr_accessor :alive, :sleep_time, :timeout, :workers_number, :worker_options, :queue, :workers_pool

    def initialize(options=nil)
      self.alive = true

      if (options && options.class == Hash)
        @sleep_time = options[:sleep_time]
        @workers_number = options[:workers_number]
        @worker_options = options[:worker_options]
        @queue = options[:queue]
        @timeout = options[:timeout]
      end

      @sleep_time ||= DEFAULT_SLEEP_TIME
      @workers_number ||= DEFAULT_WORKERS_NUMBER
      @worker_options ||= DEFAULT_WORKER_OPTIONS
      @timeout ||= DEFAULT_TIMEOUT

      @workers_pool = Delayed::HomePool.new(@workers_number, @worker_options)
    end

    def start
      t = Thread.new do
        while (@alive)
          begin
            Timeout.timeout(@timeout) do
              #puts "doing work for queue #{@queue}"
              available_workers = @workers_pool.get_available_workers

              if (available_workers && available_workers.count > 0)
                DelayedJobActiveRecordThreaded.logger.info "#{available_workers.count} available workers" if DelayedJobActiveRecordThreaded.logger
                jobs = pull_next(@queue, available_workers.count)
                available_workers.each_with_index { |w,i| w.assign_job(jobs[i]) }
              end
            end
          rescue
            begin
              DelayedJobActiveRecordThreaded.logger.error($!.backtrace.join("\n")) if DelayedJobActiveRecordThreaded.logger
            rescue
              # logging failed probably due to IO error?
            end
          end
          sleep(@sleep_time)
        end
      end
    end

    def pull_next(queue, n=15)
      #return  [ Delayed::FakeJob.new(queue) ] * n
      query = Delayed::Job.where("run_at < ?", DateTime.now).order("priority asc, run_at asc, id asc").limit(n);#.lock(true);
      if (queue)
        return query.where("queue = ?", queue)
      end
      return query
    end

    def kill
      @alive = false
    end
  end
end