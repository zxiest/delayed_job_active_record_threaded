# copied from https://github.com/collectiveidea/delayed_job_active_record/blob/master/lib/generators/delayed_job/upgrade_generator.rb

#require 'generators/delayed_job/delayed_job_generator'
require 'rails/generators/migration'
require 'rails/generators/active_record/migration'

# Extend the DelayedJobGenerator so that it creates an AR migration
module DelayedJob
  class UpgradeGenerator < Rails::Generators::Base
    include Rails::Generators::Migration
    extend ActiveRecord::Generators::Migration

    self.source_paths << File.join(File.dirname(__FILE__), 'templates')

    def create_migration_file
      migration_template 'upgrade_migration.rb', 'db/migrate/add_columns_to_delayed_jobs.rb'
    end
  end
end
