require 'spec_helper'
require 'timeout'

class TestWorker
  def perform(test)
  end
end

class ErrorWorker
  def perform(test)
    raise 'error'
  end
end

class TestLogger
  def self.info(message)
  end

  def self.error(message)
  end
end

describe Deferrer::Runner do
  let(:identifier) { 'some_identifier' }
  let(:redis) { Deferrer.redis }
  let(:list_key) { Deferrer::LIST_KEY }
  let(:callback) { lambda { } }

  describe "run" do
    it "processes jobs" do
      expect_any_instance_of(TestWorker).to receive(:perform).with('test')
      Deferrer.defer_in(-1, identifier, TestWorker, 'test')
      Deferrer.run(single_run: true)
    end

    it "converts symbols to strings when converting to json and back" do
      expect_any_instance_of(TestWorker).to receive(:perform).with({ "a" => "b"})

      Deferrer.defer_in(-1, identifier, TestWorker, { a: :b })
      Deferrer.run(single_run: true)
    end

    it "logs info messages" do
      expect(TestLogger).to receive(:info).with("Executing: deferred:#{identifier}")
      Deferrer.logger = TestLogger
      Deferrer.defer_in(-1, identifier, TestWorker, 'test')
      Deferrer.run(single_run: true)
    end

    it "rescues standard errors and logs error messages" do
      expect(TestLogger).to receive(:error).with("Error: RuntimeError: error")
      Deferrer.logger = TestLogger
      Deferrer.defer_in(-1, identifier, ErrorWorker, 'test')
      Deferrer.run(single_run: true)
    end

    it "rescues exceptions and logs and error messages" do
      expect(TestLogger).to receive(:error).with("Error: Exception: error")
      allow_any_instance_of(ErrorWorker).to receive(:perform) { raise Exception.new('error') }

      Deferrer.logger = TestLogger
      Deferrer.defer_in(-1, identifier, ErrorWorker, 'test')
      expect { Deferrer.run(single_run: true) }.to raise_error
    end

    it "runs before callback" do
      expect(callback).to receive(:call)
      Deferrer.defer_in(-1, identifier, TestWorker, 'test')
      Deferrer.run(single_run: true, before_each: callback)
    end

    it "runs after callback" do
      expect(callback).to receive(:call)
      Deferrer.defer_in(-1, identifier, TestWorker, 'test')
      Deferrer.run(single_run: true, after_each: callback)
    end
  end

  describe ".defer_at" do
    it "deferrs at given time" do
      Deferrer.defer_at(Time.now, identifier, TestWorker, 'test')

      expect(redis.zrangebyscore(list_key, '-inf', Time.now.to_f, :limit => [0, 1]).first).not_to be_nil
      expect(redis.exists(item_key(identifier))).to be_truthy
    end
  end

  describe ".defer_in" do
    it "defers in given interval" do
      Deferrer.defer_in(1, identifier, TestWorker, 'test')

      expect(redis.zrangebyscore(list_key, '-inf', (Time.now + 1).to_f, :limit => [0, 1]).first).not_to be_nil
      expect(redis.exists(item_key(identifier))).to be_truthy
    end
  end

  describe ".next_item" do
    it "returns the next item" do
      Deferrer.defer_at(Time.now, identifier, TestWorker, 'test')

      item = Deferrer.next_item

      expect(item['class']).to eq(TestWorker.to_s)
      expect(item['args']).to eq(['test'])
    end

    it "returns last update of an item" do
      Deferrer.defer_at(Time.now - 3, identifier, TestWorker, 'test1')
      Deferrer.defer_at(Time.now - 2, identifier, TestWorker, 'test2')

      item = Deferrer.next_item

      expect(item['class']).to eq(TestWorker.to_s)
      expect(item['args']).to eq(['test2'])
    end

    it "keep the old score value" do
      Deferrer.defer_at(Time.now - 3, identifier, TestWorker, 'test1')
      Deferrer.defer_at(Time.now + 1, identifier, TestWorker, 'test2')

      expect(Deferrer.next_item).not_to be_nil
    end

    it "returns nil when no next item" do
      expect(Deferrer.next_item).to be_nil
    end

    it "removes values from redis" do
      Deferrer.defer_at(Time.now, identifier, TestWorker, 'test')

      item = Deferrer.next_item

      expect(redis.zrangebyscore(list_key, '-inf', Time.now.to_f, :limit => [0, 1]).first).to be_nil
      expect(redis.exists(item_key(identifier))).to be_falsey
      expect(Deferrer.next_item).to be_nil
    end

    it "doesn't block on empty lists" do
      Deferrer.defer_in(-1, identifier, TestWorker, 'test')
      redis.del(item_key(identifier))

      Timeout::timeout(2) { expect(Deferrer.next_item).to be_nil }
      expect(redis.zrangebyscore(list_key, '-inf', 'inf', :limit => [0, 1]).first).to be_nil
    end
  end

  describe "inline" do
    before :each do
      Deferrer.inline = true
    end

    after :each do
      Deferrer.inline = false
    end

    it "does performs jobs inline" do
      expect_any_instance_of(TestWorker).to receive(:perform).with({ "a" => "b"})

      Deferrer.defer_in(-1, identifier, TestWorker, { a: :b })
    end
  end
end
