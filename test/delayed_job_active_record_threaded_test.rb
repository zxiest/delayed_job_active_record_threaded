require "test_helper"
require "delayed_job_active_record_threaded"
require "rails"
require "rails/test_help"
require "minitest/rails"

class TestJob < Struct.new(:id)
  def perform
    story = Story.find(id)
    sleep(rand(2))
    puts "Telling #{story.text}\n" if story
  end
end

class CrashingJob < TestJob
  def perform
    raise "failing job"
  end
end

class DelayedJobActiveRecordThreadedTest < ActiveSupport::TestCase #MiniTest::Unit::TestCase
  self.use_transactional_fixtures = false

  QUEUE_NAME = "StoriesQueue"
  WORKING_STORIES = 100
  CRASHING_STORIES = 10

  def prepare_failing_stories
    CRASHING_STORIES.times { |i|
      s = Story.create!(:text => "Story #{i}")
      Delayed::Job.enqueue(CrashingJob.new(s.id), :queue => QUEUE_NAME, :priority => i, :delayable_id => s.id, :delayable_type => s.class.name, :run_at => 10.seconds.ago)
    }
  end

  before do
    #Delayed::Job.new(:run_at => 10.seconds.ago).save
    WORKING_STORIES.times { |i|
      s = Story.create!(:text => "Story #{i}")
      Delayed::Job.enqueue(TestJob.new(s.id), :queue => QUEUE_NAME, :priority => i, :delayable_id => s.id, :delayable_type => s.class.name, :run_at => 10.seconds.ago)
    }
  end

  after do
    Story.delete_all
  end

  # this is VERY dependent on the database pool size
  test "should process jobs without crashing" do
    Celluloid.boot # fixes Celluloid issue "Thread pool is not running"
    mgr = Delayed::HomeManager.new({ :sleep_time => 1, :workers_number => 25, :queue => QUEUE_NAME })

    puts "Number of jobs in queue is: #{Delayed::Job.count}"

    mgr.start

    sleep(10)

    mgr.kill

    puts "Number of threads: #{Thread.list.count}"

    assert Delayed::Job.where("queue = ?", QUEUE_NAME).count == 0, "Expected to have an empty queue after 10 seconds. Queue size was #{Delayed::Job.count} instead"
  end

  test "pool should maintain the number of workers and not crash" do
    Celluloid.boot # fixes Celluloid issue "Thread pool is not running"
    mgr = Delayed::HomeManager.new({ :sleep_time => 0.5, :workers_number => 50, :queue => QUEUE_NAME })
    mgr.start
    sleep(3)

    assert mgr.workers_pool.size == 50, "Pool is expected to maintain its size, got size of #{mgr.workers_pool.size} instead"

    assert mgr.alive, "Expected Manager to be alive after completing queue"

    mgr.kill
  end

  test "should succeed and maintain pool size even if workers have crashing job" do
    prepare_failing_stories

    assert (Story.count == (CRASHING_STORIES+WORKING_STORIES)), "test expects to start with #{(CRASHING_STORIES+WORKING_STORIES)} stories, got #{Story.count} instead"

    Celluloid.boot # fixes Celluloid issue "Thread pool is not running"
    mgr = Delayed::HomeManager.new({ :sleep_time => 0.5, :workers_number => 50, :queue => QUEUE_NAME })

    mgr.start
    sleep(3)

    assert mgr.workers_pool.size == 50, "Pool is expected to maintain its size, got size of #{mgr.workers_pool.size} instead"

    assert mgr.alive, "Expected Manager to be alive after completing queue"

    mgr.kill
  end
end