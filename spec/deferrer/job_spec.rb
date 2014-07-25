require 'spec_helper'

class Worker
  include Deferrer::Job
  pool_options size: 3

  class << self
    attr_accessor :queue
  end

  def perform(i)
    self.class.queue.push(i)
  end
end

describe Deferrer::Job do
  it "performs work asynchronously" do
    total = 20
    Worker.queue = Queue.new

    total.times { |i| Deferrer.defer_in(-1, i, Worker, i) }

    Deferrer.run(single_run: true)

    expect(total.times.map { Worker.queue.pop }.sort).to eq(total.times.to_a)
  end

  it "responds to pool when Deferrer::Job included" do
    expect(Worker).to respond_to(:pool)
  end

  it "sets the Deferrer::Job pool size to 3" do
    expect(Worker.pool.size).to eq(3)
  end

  it "returns the same pool" do
    expect(Worker.pool).to eq(Worker.pool)
  end
end
