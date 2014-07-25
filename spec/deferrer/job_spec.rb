require 'spec_helper'

class Worker
  include Deferrer::Job
  pool_options size: 2

  class << self
    attr_accessor :queue
  end

  def perform(i)
    self.class.queue.push(i)
  end
end

describe Deferrer::Job do
  it "performs work asynchronously" do
    total = 10
    Worker.queue = Queue.new

    total.times { |i| Deferrer.defer_in(-1, i, Worker, i) }

    Deferrer.run(single_run: true)

    expect(total.times.map { Worker.queue.pop }).to eq(total.times.to_a)
  end
end
