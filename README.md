# DelayedJobActiveRecordThreaded [![Build Status](https://travis-ci.org/zxiest/delayed_job_active_record_threaded.png)](http://travis-ci.org/zxiest/delayed_job_active_record_threaded)

<br/>
DelayedJob allows you to execute long-running jobs at a later time. For more information on how to create and delay a job, follow https://github.com/collectiveidea/delayed_job

This gem processes your delayed jobs with a single threaded process (instead of multiple processes). 
This helps avoid database deadlocks and saves computing resources.

<hr/>
## Installation

Add this line to your application's Gemfile:

    gem 'delayed_job_active_record_threaded'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install delayed_job_active_record_threaded

## Setup
<b>Make sure to pick the correct setup method prior to proceeding</b>

### Fresh setup
Follow this setup method if you do have not been using delayed_job_active_record in your project and do not have a "delayed_jobs" table created:
    
    $ rails generate delayed_job:active_record
    $ rake db:migrate

### Upgrading from delayed_job_active_record
If you were previously using delayed_job_active_record, follow the steps below:

    $ rails generate delayed_job:upgrade
    $ rake db:migrate
    
The lines above will add additional columns to your delayed_jobs table.

## Usage
### Delaying work
Any object that respond_to? perform can be delayed.

    class EbookProcessor
        def initialize(ebook_id)
            @ebook_id = ebook_id
        end

        def perform
            ebook = Ebook.find_by_id(@ebook_id)
            # run long-running process
        end
    end

In order to create a job and push it to the queue, do the following:

    Delayed::Job.enqueue EbookProcessor.new(Ebook.find_by_name('The Power of Habit').id), :queue => 'ebooks_queue'

When :queue is not provided, the job will be pushed to the default queue (queue with name 'default' or nil). 
Read below if you wish to process multiple queues simultaneously.

Another way of delaying work is to call the method delay on an object:

    EbookProcessor.new(Ebook.find_by_name('The Power of Habit').id).delay

### Delaying mailers

Mailers work differently and can be delayed this way:

    UserMailer.delay(:queue => 'mailers').welcome_user(13)

<hr/>
### WARNING
As you may have noticed in call to welcome_user above, we did not pass a user object but rather the user's id. This is a very important notion when using delayed_job.
Never pass an object to delayed job unless you are certain it can be deserialized.
Especially avoid passing ActiveRecord::Base objects. If you do, you will be wondering why your delayed_jobs are failing silently.

For instance, the following code is <b>BAD</b>:

    # WARNING: NEVER DO THIS
    @user = User.find(13)
    UserMailer.delay(:queue => 'mailers').welcome_user(@user)

</span></p><br/>
For more information about delayed_jobs, check out https://github.com/collectiveidea/delayed_job

<hr/>
## Running Queue Processors

### Default
The commands below are equivalent and run a process that goes through the jobs in the delayed_jobs table:

    $ bundle exec rake delayed_job:start
    $ bundle exec rake dj:start

### Multiple Queues and Extra Options
The default task processes all the jobs in all queues. In order to allow queue separation and prioritization, you would want to categorize your jobs and push them to different queues.

Also, you can have multiple queues processed simultaneously, each with its own options. In the example below, we assume you have an "ebooks" and an "albums" queues.

The commands below will process the queues ebooks and albums simultaneously:

    $ bundle exec rake "dj:start[ebooks&albums]"
    $ bundle exec rake "dj:start[ebooks[workers_number]=16&ebooks[worker_timeout]=60&albums[workers_number]=32&albums[worker_timeout]=120]"

The expression "ebooks[workers_number]=16&ebooks[worker_timeout]=60" is a parsed similarly to a URL's query string and would be converted into the following hash:

    {"ebooks"=>{"workers_number"=>"16", "worker_timeout"=>"60"}, "albums"=>{"workers_number"=>"32", "worker_timeout"=>"120"}}

The rake task above will start a process in the background and process two queues, "ebooks" with 16 working threads and times out after 60 seconds and "albums" with 32 working threads and times out after 120 seconds.

Note that, if you specify the name of one queue, you must specify the other queues as well if you wish them to be processed.

### Starting/Stopping on Production
In order to start and stop delayed_job on production (or any other environenment), pass along the RAILS_ENV variable.

    $ RAILS_ENV=production bundle exec rake dj:start
    $ RAILS_ENV=production bundle exec rake dj:stop
    
The pid file will be in tmp/pids/delayed_job_production.pid and the log file will be in log/delayed_job_production.log

Note that the task dj:start spawns a background process that calls dj:run and does not die when you disconnect from the terminal.

<b>Default options:</b>
    
    workers_number: 16
    worker_timeout: 60

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
