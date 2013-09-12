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

    attr_accessor :alive, :timeout, :sleep_time, :workers_number, :queue, :workers_pool, :max_attempts, :worker_options, :timer

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
      @workers_pool = HomeWorker.pool(:size => @workers_number, :args => @worker_options)

      @timer = every(@sleep_time) {
        begin
          if (!@alive)
            @timer.stop
          end

          jobs = pull_next(@queue, @workers_pool.idle_size)
          jobs.each { |j| @workers_pool.async.work(j) }
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

    def pull_next(queue, n=15)
      #return  [ Delayed::FakeJob.new(queue) ] * n
      ids = []
      Delayed::Job.transaction do
        query = Delayed::Job.where("run_at < ? and locked_at is null", DateTime.now).order("priority asc, run_at asc, id asc")#.limit(n);#.lock(true);
        if (queue)
          query = query.where("queue = ?", queue)
        end

        query = query.limit(n)
        ids = query.pluck(:id)
        query.update_all(:locked_at => DateTime.now.utc)
      end


      return Delayed::Job.where(:id => ids)
    end

    def kill
      @alive = false
    end
  end
end