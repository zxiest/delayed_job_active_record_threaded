# DelayedJobActiveRecordThreaded [![Build Status](https://travis-ci.org/zxiest/delayed_job_active_record_threaded.png)](http://travis-ci.org/zxiest/delayed_job_active_record_threaded)

DelayedJob allows you to execute long-running jobs at a later time. For more information on how to create and delay a job, follow https://github.com/collectiveidea/delayed_job

This gem processes your delayed jobs with a single threaded process (instead of multiple processes). 
This helps avoid database deadlocks and saves computing resources.

## Installation

Add this line to your application's Gemfile:

    gem 'delayed_job_active_record_threaded'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install delayed_job_active_record_threaded


## Setup
Make sure to pick the correct setup method prior to proceeding:

### Fresh setup
Follow this setup method if you do have not been using delayed_job_active_record in your project and do not have a "delayed_jobs" table created:
    
    $ rails generate delayed_job:active_record
    $ rake db:migrate

### Upgrading from delayed_job_active_record

If you were previously using delayed_job_active_record, follow the steps below:

    $ rails generate delayed_job:upgrade
    $ rake db:migrate
    
This will add columns to your delayed_jobs table.

## Usage

For information on how to create delayed_jobs and enqueue them, follow https://github.com/collectiveidea/delayed_job

In order to start the threaded process this gem provides, use the following:

### Defaults

    $ bundle exec rake delayed_job:start
or
    $ bundle exec rake dj:start

### With Options

The default task processes items belonging to all the queues. This is, most of times, not desirable as tasks with higher priority in a given queue take precedence over tasks in another queue.

You can have multiple queues processed simultaneously, each with its own options.
In the example below, we assume you have an "ebooks" and an "albums" queues.

The command below will process the queues ebooks and albums simultaneously
    $ bundle exec rake "dj:start[ebooks&albums]"

    $ bundle exec rake "dj:start[ebooks[workers_number]=16&ebooks[worker_timeout]=60&albums[workers_number]=32&albums[worker_timeout]=120]"

The expression "ebooks[workers_number]=16&ebooks[worker_timeout]=60" is a parsed similarly to a URL's query string and would be converted into the following hash:

    {"ebooks"=>{"workers_number"=>"16", "worker_timeout"=>"60"}, "albums"=>{"workers_number"=>"32", "worker_timeout"=>"120"}}

The rake task above will start a process in the background and process two queues, "ebooks" with 16 working threads and times out after 60 seconds and "albums" with 32 working threads and times out after 120 seconds.

Default options:
    workers_number: 16
    worker_timeout: 60

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
