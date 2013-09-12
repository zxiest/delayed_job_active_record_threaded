require 'minitest/unit'
require 'minitest/autorun'
require 'turn'


require 'yaml'
require 'active_record'
require 'delayed_job'
require "#{File.dirname(__FILE__)}/../lib/delayed_job_active_record_threaded"
require "#{File.dirname(__FILE__)}/../lib/delayed/job"

# copied (and modified) from https://github.com/collectiveidea/delayed_job_active_record/blob/master/spec/helper.rb
begin
  require 'protected_attributes'
rescue LoadError
end

$logger = Logger.new('/tmp/dj.log')
ENV['RAILS_ENV'] = 'test'

db_adapter, gemfile = ENV["ADAPTER"], ENV["BUNDLE_GEMFILE"]
db_adapter ||= gemfile && gemfile[%r(gemfiles/(.*?)/)] && $1
#db_adapter ||= 'sqlite3'
db_adapter ||= 'mysql2'

config = YAML.load(File.read('test/database.yml'))
ActiveRecord::Base.establish_connection config[db_adapter]
ActiveRecord::Base.logger = $logger
ActiveRecord::Migration.verbose = true

ActiveRecord::Schema.define do
  create_table :delayed_jobs, :force => true do |table|
    table.integer  :priority, :default => 0
    table.integer  :attempts, :default => 0
    table.text     :handler
    table.text     :last_error
    table.datetime :run_at
    table.datetime :locked_at
    table.datetime :failed_at
    table.string   :locked_by
    table.string   :queue
    table.integer  :delayable_id
    table.string   :delayable_type
    table.timestamps
  end

  add_index :delayed_jobs, [:priority, :run_at], :name => 'delayed_jobs_priority'
  add_index :delayed_jobs, [:delayable_id, :delayable_type], :name => 'delayed_jobs_delayable'

  create_table :stories, :primary_key => :story_id, :force => true do |table|
    table.string :text
    table.boolean :scoped, :default => true
  end
end

# Purely useful for test cases...
class Story < ActiveRecord::Base
  if ::ActiveRecord::VERSION::MAJOR < 4 && ActiveRecord::VERSION::MINOR < 2
    set_primary_key :story_id
  else
    self.primary_key = :story_id
  end
  def tell; text; end
  def whatever(n, _); tell*n; end
  default_scope { where(:scoped => true) }

  handle_asynchronously :whatever
end

# Add this directory so the ActiveSupport autoloading works
ActiveSupport::Dependencies.autoload_paths << File.dirname(__FILE__)