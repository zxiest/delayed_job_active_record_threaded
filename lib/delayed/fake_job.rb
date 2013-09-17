module Delayed
  class FakeJob
    @@count = 1
    @@lock = Mutex.new
    attr_accessor :run_at, :attempts, :object_id, :object_type, :id, :queue

    def initialize(queue=nil)
      @run_at = DateTime.now
      @attempts = 0
      @queue = queue

      @@lock.synchronize {
        @id = @@count
        @@count += 1
      }
    end

    def invoke_job
      DelayedJobActiveRecordThreaded.logger.info "invoking job #{@id} in queue #{@queue}" if DelayedJobActiveRecordThreaded.logger
      sleep(rand * 5)
    end

    def perform
      invoke_job
    end

    def delete
      DelayedJobActiveRecordThreaded.logger.info "deleting job #{@id}" if DelayedJobActiveRecordThreaded.logger
    end

    def save
      DelayedJobActiveRecordThreaded.logger "saving job #{@id}" if DelayedJobActiveRecordThreaded.logger
    end
  end
end