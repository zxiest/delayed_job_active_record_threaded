require 'delayed_job_active_record_threaded'
require 'rails'

module Delayed
  class Railtie < Rails::Railtie
    rake_tasks do
      load "#{File.dirname(__FILE__)}/../tasks/dj.rake"
    end
  end
end
