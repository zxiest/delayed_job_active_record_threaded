namespace :delayed_job do
  task :run => :environment do |t, args|
    Delayed::HomeManager.new({ :sleep_time => 5, :workers_number => 5, :queue => "default", :worker_options => { :timeout => 120 } }).start

    # stay alive
    while(true)
      sleep(5)
    end
  end

  def dj_pid
    return 'tmp/pids/delayed_job.pid'
  end

  task :start => :environment do |t, args|
    cmd = %(if [ -f #{dj_pid} ] && [ -n `cat #{dj_pid}` ] && [ ps -p `cat #{dj_pid}` > /dev/null ]; then sudo kill `cat #{dj_pid}`; fi
            (bundle exec rake delayed_job:run >> log/delayed_job.log 2>&1) & (echo $! > tmp/pids/dj.pid)
           )

    # execute cmd
    %x(#{cmd})
  end

  task :stop => :environment do |t, args|
    cmd = %(if [ -f #{dj_pid} ] && [ -n `cat #{dj_pid}` ] && [ ps -p `cat #{dj_pid}` > /dev/null ]; then sudo kill `cat #{dj_pid}`; fi)

    # execute cmd
    %x(#{cmd})
  end
end