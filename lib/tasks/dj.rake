require 'rack/utils'

namespace :dj do
  task :run, [:args_expr ] => :environment do |t,args|
    Rake::Task["delayed_job:run"].invoke(args[:args_expr].nil? ? args : args[:args_expr])
  end

  task :start, [:args_expr ] => :environment do |t,args|
    Rake::Task["delayed_job:start"].invoke(args[:args_expr].nil? ? args : args[:args_expr])
  end

  task :stop, [:args_expr ] => :environment do |t,args|
    Rake::Task["delayed_job:stop"].invoke
  end

  task :kill_all, [:args_expr ] => :environment do |t,args|
    Rake::Task["delayed_job:kill_all"].invoke
  end

  task :print_options, [:args_expr ] => :environment do |t,args|
    Rake::Task["delayed_job:print_options"].invoke(args[:args_expr].nil? ? args : args[:args_expr])
  end
end

namespace :delayed_job do
  # allow passing args like querystring
  # parse args with Rack::Utils.parse_nested_query(query)
  # (must require 'rack/utils')
  # rake "delayed_job:run[default[workers_number]=16&default[worker_timeout]=120]"
  task :run, [ :args_expr ] => :environment do |t, args|
    DEFAULT_QUEUE_NAME = nil
    DEFAULT_WORKERS_NUMBER = 16
    DEFAULT_WORKERS_TIMEOUT = 60

    args.with_defaults(:args_expr => "default[workers_number]=16&default[worker_timeout]=60")
    puts "args: #{args[:args_expr]}"

    options = Rack::Utils.parse_nested_query(args[:args_expr])
    puts "options #{options}"

    options.keys.each do |k|
      queue_name = k
      if options[k]
        workers_number = options[k]["workers_number"]
        workers_timeout = options[k]["worker_timeout"]
        # in case param is misspelled
        workers_timeout ||= options[k]["workers_timeout"]
      end

      queue_name ||= DEFAULT_QUEUE_NAME
      workers_number ||= DEFAULT_WORKERS_NUMBER
      workers_timeout ||= DEFAULT_WORKERS_TIMEOUT

      # set to nil of queue_name is default
      queue_name = nil if (queue_name == "default")

      puts "queue: #{queue_name}, workers_number: #{workers_number}, workers_timeout: #{workers_timeout}"

      Delayed::HomeManager.new({ :workers_number => workers_number.to_i, :queue => queue_name, :worker_options => { :timeout => workers_timeout.to_i } }).start
    end

    # stay alive
    while(true)
      sleep(5)
    end
  end

  def dj_pid
    return 'tmp/pids/delayed_job.pid'
  end

  task :start, [ :args_expr ] => :environment do |t, args|
    puts "#{args[:args_expr]}"

    cmd = %(if [ -f #{dj_pid} ] && [ -n `cat #{dj_pid}` ] && [ ps -p `cat #{dj_pid}` > /dev/null ]; then sudo kill -9 `cat #{dj_pid}`; fi
            (bundle exec rake "delayed_job:run[#{args[:args_expr]}]" >> log/delayed_job.log 2>&1) & (echo $! > tmp/pids/dj.pid)
           )

    puts "executing: #{cmd}"

    # execute cmd
    %x(#{cmd})
  end

  task :stop => :environment do |t, args|
    cmd = %(if [ -f #{dj_pid} ] && [ -n `cat #{dj_pid}` ] && [ ps -p `cat #{dj_pid}` > /dev/null ]; then kill -9 `cat #{dj_pid}`; fi)

    # execute cmd
    %x(#{cmd})
  end

  task :print_options, [ :args_expr ] => :environment do |t, args|
    args.with_defaults(:args_expr => "name=abdo&fruits[]=bananas&fruits[]=dates")
    options = Rack::Utils.parse_nested_query(args[:args_expr])

    puts options
  end

  task :kill_all do
    cmd = %(ps aux | grep delayed_job | awk -F" " '{ print $2 }' | xargs kill -9)
    %x(#{cmd})
  end
end