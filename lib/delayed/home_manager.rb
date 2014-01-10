require 'date_core'
require 'celluloid'
require 'timers'

module Delayed
  class HomeManager
    include Celluloid

    DEFAULT_SLEEP_TIME = 2
    DEFAULT_JOBS_TO_PULL = 20
    DEFAULT_WORKERS_NUMBER = 16
    DEFAULT_TIMEOUT = 20
    DEFAULT_MAX_ATTEMPTS = 25

    attr_accessor :alive, :timeout, :sleep_time, :workers_number, :queue, :workers_pool, :max_attempts, :worker_options, :timer, :hostname

    def initialize(options=nil)
      self.alive = true

      if (options && options.class == Hash)
        @sleep_time = options[:sleep_time]
        @workers_number = options[:workers_number]
        @worker_options = options[:worker_options]
        @queue = options[:queue]
        @timeout = options[:timeout]
        @max_attempts = options[:max_attempts]
      end

      @sleep_time ||= DEFAULT_SLEEP_TIME
      @timeout ||= DEFAULT_TIMEOUT
      @workers_number ||= DEFAULT_WORKERS_NUMBER
      @max_attempts ||= DEFAULT_MAX_ATTEMPTS
      @worker_options ||= {}
    end

    def start
      # use Celluloid to create a pool of size @workers_number
      # worker_options get passed to HomeWorker's initializer
      @workers_pool = HomeWorker.pool(:size => @workers_number, :args => @worker_options)

      begin
        # make sure jobs locked by our hostname in prior attempts are unlocked
        unlock_all
      rescue
        DelayedJobActiveRecordThreaded.logger.error($!.message) if DelayedJobActiveRecordThreaded.logger
        DelayedJobActiveRecordThreaded.logger.error($!.backtrace.join("\n")) if DelayedJobActiveRecordThreaded.logger
      end

      @timer = every(@sleep_time) {
        begin
          if (!@alive)
            @timer.cancel
          else
            jobs = pull_next(@queue, @workers_pool.idle_size)
            jobs.each { |j| @workers_pool.async.work(j) }
          end
        rescue
          # logging error watch
          begin
            DelayedJobActiveRecordThreaded.logger.error($!.message) if DelayedJobActiveRecordThreaded.logger
            DelayedJobActiveRecordThreaded.logger.error($!.backtrace.join("\n")) if DelayedJobActiveRecordThreaded.logger
          rescue
          end
        end
      }
    end

    # Unlock all jobs locked by our hostname in prior attempts
    def unlock_all
      Delayed::Job.transaction do
        Delayed::Job.where(:locked_by => hostname).update_all(:locked_by => nil, :locked_at => nil)
      end
    end

    # pull n items from Delayed::Job
    # locks jobs until they're processed (the worker then deletes the job)
    def pull_next(queue=nil, n=15)
      ids = []
      Delayed::Job.transaction do
        query = Delayed::Job.where("(run_at is null or run_at < ?) and locked_at is null", DateTime.now).order("priority asc, run_at asc, id asc")
        if (queue)
          query = query.where(:queue => queue)
        end

        query = query.limit(n)
        ids = query.pluck(:id)
        query.update_all(:locked_at => DateTime.now.utc, :locked_by => hostname)
      end

      return Delayed::Job.where(:id => ids)
    end

    def hostname
      @hostname ||= Socket.gethostname
      return @hostname
    end

    def kill
      @alive = false
    end
  end
end