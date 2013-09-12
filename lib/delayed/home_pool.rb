module Delayed
  class HomePool
    DEFAULT_WORKERS_NUMBER=6

    attr_accessor :workers, :workers_number, :workers_options

    def initialize(workers_number, workers_options=nil)
      @workers_number = workers_number
      @workers_options = workers_options
      @workers = []

      @workers_number.times {
        @workers << Delayed::HomeWorker.new(@workers_options)
      }

      # start all workers
      @workers.map(&:start)
    end

    def get_available_workers
      return @workers.select { |w| w.available? }
    end
  end
end