require "test_helper"
require "delayed_job_active_record_threaded"
require "rails"
require "rails/test_help"
require "minitest/rails"

class TestJob < Struct.new(:id)
  def perform
    story = Story.find(id)
    sleep(rand(2))
    puts "Telling #{story.text}" if story
  end
end

class DelayedJobActiveRecordThreadedTest < ActiveSupport::TestCase #MiniTest::Unit::TestCase
  self.use_transactional_fixtures = false

  QUEUE_NAME = "StoriesQueue"

  before do
    #Delayed::Job.new(:run_at => 10.seconds.ago).save
    10000.times { |i|
      s = Story.create!(:text => "Story #{i}")
      Delayed::Job.enqueue(TestJob.new(s.id), :queue => QUEUE_NAME, :priority => i, :delayable_id => s.id, :delayable_type => s.class.name, :run_at => 10.seconds.ago)
    }
  end

  after do
  end

  # this is VERY dependent on the database pool size
  test "should process jobs without crashing" do
    mgr = Delayed::HomeManager.new({ :sleep_time => 5, :workers_number => 300, :queue => QUEUE_NAME })

    puts "Number of jobs in queue is: #{Delayed::Job.count}"

    mgr.start

    sleep(5000)
    assert Delayed::Job.where("queue = ?", QUEUE_NAME).count == 0, "Expected to have an empty queue after 10 seconds. Queue size was #{Delayed::Job.count} instead"
  end
end