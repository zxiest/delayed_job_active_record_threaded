# copied from https://github.com/collectiveidea/delayed_job_active_record/blob/master/lib/generators/delayed_job/templates/upgrade_migration.rb

class AddQueueToDelayedJobs < ActiveRecord::Migration
  def self.up
    add_column :delayed_jobs, :queue, :string
    add_column :delayed_jobs, :delayable_id, :integer
    add_column :delayed_jobs, :delayable_type, :string
  end

  def self.down
    remove_column :delayed_jobs, :queue
    remove_column :delayed_jobs, :delayable_id
    remove_column :delayed_jobs, :delayable_type
  end
end
