require 'spec_helper'

describe Deferrer::Job do
  it "performs work asynchronously" do
    total = 20

    run_sync(Worker, total) { |i| Deferrer.defer_in(-1, i, Worker, i) }

    expect(total.times.map { Worker.queue.pop }.sort).to eq(total.times.to_a)
  end

  it "is thread safe" do
    Thread.current[:x] = 1

    run_sync(Worker) { Deferrer.defer_in(-1, 'id', Worker, 1) }

    expect(Thread.current[:x]).to eq(1)
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
