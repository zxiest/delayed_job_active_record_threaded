# copied from https://github.com/collectiveidea/delayed_job_active_record/blob/master/lib/generators/delayed_job/active_record_generator.rb

require 'rails/generators/migration'
require 'rails/generators/active_record'

# Extend the DelayedJobGenerator so that it creates an AR migration
module DelayedJob
  class ActiveRecordGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    self.source_paths << File.join(File.dirname(__FILE__), 'templates')

    def create_migration_file
      migration_template 'migration.rb', 'db/migrate/create_delayed_jobs.rb'
    end

    def self.next_migration_number dirname
      ActiveRecord::Generators::Base.next_migration_number dirname
    end
  end
end