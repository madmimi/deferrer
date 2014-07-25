require 'spec_helper'

describe Deferrer::Runner do
  let(:identifier) { 'identifier' }
  let(:redis) { Deferrer.redis }
  let(:list_key) { Deferrer::LIST_KEY }
  let(:logger) { Logger.new(STDOUT) }

  describe ".run" do
    it "processes jobs" do
      run_sync(Worker) { Deferrer.defer_in(-1, identifier, Worker, 'test') }

      expect(Worker.queue.pop).to eq('test')
    end

    it "converts symbols to strings when converting to json and back" do
      run_sync(Worker) { Deferrer.defer_in(-1, identifier, Worker, { a: :b }) }

      expect(Worker.queue.pop).to eq({ "a" => "b"})
    end

    it "rescues standard errors" do
      allow(Deferrer).to receive(:next_item) { raise RuntimeError.new('error') }

      run_sync(Worker) { Deferrer.defer_in(-1, identifier, Worker, 'test') }
    end

    it "rescues exceptions and logs and error messages" do
      allow(Deferrer).to receive(:next_item) { raise Exception.new('error') }

      expect { run_sync(Worker) { Deferrer.defer_in(-1, identifier, Worker, 'test') } }.to raise_error
    end

    it "raises error if worker class does not include Deferrer::Job" do
      expect {
        run_sync(WorkerWithoutDeferrerJob) {
          Deferrer.defer_in(-1, identifier, WorkerWithoutDeferrerJob, 'test')
        }
      }.to raise_error(Deferrer::WorkerNotImplemented)
    end
  end

  describe ".next_item" do
    it "returns the next item" do
      Deferrer.defer_at(Time.now, identifier, Worker, 'test')

      item = Deferrer.next_item

      expect(item['class']).to eq(Worker.to_s)
      expect(item['args']).to eq(['test'])
    end

    it "returns last update of an item" do
      Deferrer.defer_at(Time.now - 3, identifier, Worker, 'test1')
      Deferrer.defer_at(Time.now - 2, identifier, Worker, 'test2')

      item = Deferrer.next_item

      expect(item['class']).to eq(Worker.to_s)
      expect(item['args']).to eq(['test2'])
    end

    it "keep the old score value" do
      Deferrer.defer_at(Time.now - 3, identifier, Worker, 'test1')
      Deferrer.defer_at(Time.now + 1, identifier, Worker, 'test2')

      expect(Deferrer.next_item).not_to be_nil
    end

    it "returns nil when no next item" do
      expect(Deferrer.next_item).to be_nil
    end

    it "removes values from redis" do
      Deferrer.defer_at(Time.now, identifier, Worker, 'test')

      item = Deferrer.next_item

      expect(redis.zrangebyscore(list_key, '-inf', Time.now.to_f, :limit => [0, 1]).first).to be_nil
      expect(redis.exists(item_key(identifier))).to be_falsey
      expect(Deferrer.next_item).to be_nil
    end

    it "doesn't block on empty lists" do
      Deferrer.defer_in(-1, identifier, Worker, 'test')
      redis.del(item_key(identifier))

      expect(Deferrer.next_item).to be_nil
      expect(redis.zrangebyscore(list_key, '-inf', 'inf', :limit => [0, 1]).first).to be_nil
    end
  end

  describe ".defer_at" do
    it "deferrs at given time" do
      Deferrer.defer_at(Time.now, identifier, Worker, 'test')

      expect(redis.zrangebyscore(list_key, '-inf', Time.now.to_f, :limit => [0, 1]).first).not_to be_nil
      expect(redis.exists(item_key(identifier))).to be_truthy
    end
  end

  describe ".defer_in" do
    it "defers in given interval" do
      Deferrer.defer_in(1, identifier, Worker, 'test')

      expect(redis.zrangebyscore(list_key, '-inf', (Time.now + 1).to_f, :limit => [0, 1]).first).not_to be_nil
      expect(redis.exists(item_key(identifier))).to be_truthy
    end
  end

  describe ".logger" do
    it "logs info messages" do
      expect(logger).to receive(:info).with(%{Executing Worker#perform with args: ["test"]})

      Deferrer.logger = logger
      run_sync(Worker) { Deferrer.defer_in(-1, identifier, Worker, 'test') }
    end

    it "logs error messages" do
      allow(Deferrer).to receive(:next_item) { raise RuntimeError.new('error') }
      expect(logger).to receive(:error).with("Error: RuntimeError: error")

      Deferrer.logger = logger
      run_sync(Worker) { Deferrer.defer_in(-1, identifier, Worker, 'test') }
    end

    it "logs exceptions messages" do
      expect(logger).to receive(:error).with("Error: Exception: error")
      allow(Deferrer).to receive(:next_item) { raise Exception.new('error') }

      Deferrer.logger = logger

      expect { run_sync(Worker) { Deferrer.defer_in(-1, identifier, Worker, 'test') } }.to raise_error
    end
  end

  describe ".inline" do
    before :each do
      Deferrer.inline = true
    end

    after :each do
      Deferrer.inline = false
    end

    it "performs jobs inline" do
      expect_any_instance_of(Worker).to receive(:perform).with({ "a" => "b"})

      Deferrer.defer_in(-1, identifier, Worker, { a: :b })
    end
  end
end
