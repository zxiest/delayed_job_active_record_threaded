# copied from https://github.com/collectiveidea/delayed_job_active_record/blob/master/lib/generators/delayed_job/templates/upgrade_migration.rb

class AddColumnsToDelayedJobs < ActiveRecord::Migration
  def self.up
    add_column :delayed_jobs, :delayable_id, :integer
    add_column :delayed_jobs, :delayable_type, :string
    remove_index :delayed_jobs, :name => "delayed_jobs_priority"
    add_index :delayed_jobs, [:failed_at, :priority, :run_at], :name => 'delayed_jobs_priority'
    add_index :delayed_jobs, [:delayable_id, :delayable_type], :name => 'delayed_jobs_object'
  end

  def self.down
    remove_column :delayed_jobs, :delayable_id
    remove_column :delayed_jobs, :delayable_type
    remove_index :delayed_jobs, :name => "delayed_jobs_priority"
    add_index :delayed_jobs, [:priority, :run_at], :name => 'delayed_jobs_priority'
  end
end
