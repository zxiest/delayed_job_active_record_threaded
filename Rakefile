require "bundler/gem_tasks"

require 'rake/testtask'
require 'active_record'
require 'active_support'
require 'active_support/core_ext'
require 'delayed_job'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = "test/*_test.rb"
end


def prepare_connection
  ENV["RAILS_ENV"] = "test"

  #ENV["ADAPTER"] ||= "mysql2"

  db_adapter, gemfile = ENV["ADAPTER"], ENV["BUNDLE_GEMFILE"]
  db_adapter ||= gemfile && gemfile[%r(gemfiles/(.*?)/)] && $1
  db_adapter ||= 'sqlite3'

  config = YAML.load(File.read('test/database.yml'))
  ActiveRecord::Base.establish_connection config[db_adapter]
  ActiveRecord::Base.logger = $logger
  ActiveRecord::Migration.verbose = false
end

task :prepare do
  prepare_connection

  Dir["db/migrate/**/*.rb"].each do |f|
    File.delete "#{File.dirname(__FILE__)}/#{f}"
  end

  require "#{File.dirname(__FILE__)}/lib/generators/delayed_job/active_record_generator"
  DelayedJob::ActiveRecordGenerator.new.create_migration_file

  require "#{File.dirname(__FILE__)}/lib/delayed/job"


  ::ActiveRecord::Base.clear_all_connections!
end

task :seed do
  prepare_connection

  require "#{File.dirname(__FILE__)}/lib/delayed/job"

  def do_once
    1000.times {
      j = Delayed::Job.new
      j.save
    }
  end

  do_once

  ::ActiveRecord::Base.clear_all_connections!
end

task :migrate do
  prepare_connection

  Dir["db/migrate/**/*.rb"].each do |f|
    require "#{File.dirname(__FILE__)}/#{f}"

    k = f.split("_")[1..-1].join("_").split(".")[0].camelize.constantize
    puts "Migrating #{k.name}"
    k.up
    puts "Done."
  end

  ::ActiveRecord::Base.clear_all_connections!
end

task :rollback do
  prepare_connection

  Dir["db/migrate/**/*.rb"].each do |f|
    require "#{File.dirname(__FILE__)}/#{f}"

    k = f.split("_")[1..-1].join("_").split(".")[0].camelize.constantize
    puts "Migrating #{k.name}"
    k.down
    puts "Done."
  end

  ::ActiveRecord::Base.clear_all_connections!
end