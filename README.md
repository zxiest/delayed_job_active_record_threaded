# URL Formatter [![Build Status](https://secure.travis-ci.org/zxiest/delayed_job_active_record_threaded.png)](http://travis-ci.org/zxiest/delayed_job_active_record_threaded)
# DelayedJobActiveRecordThreaded

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


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
