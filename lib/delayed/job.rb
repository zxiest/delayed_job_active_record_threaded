require 'active_record'
require 'delayed_job'

module Delayed
  # A job object that is persisted to the database.
  # Contains the work object as a YAML field.
  class Job < ::ActiveRecord::Base
    include Delayed::Backend::Base

    self.table_name = "delayed_jobs"
  end
end