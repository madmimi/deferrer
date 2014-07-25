require 'spec_helper'
require 'timeout'

class CarDeferrer
  def perform(car)
  end
end

class InvalidDeferrer
  def perform(car)
    raise 'error'
  end
end

class Logger
  def self.info(message)
  end

  def self.error(message)
  end
end

describe Deferrer::Runner do
  let(:car) { 'car' }
  let(:car2) { 'car2' }
  let(:identifier) { 'car1' }
  let(:redis) { Deferrer.redis }
  let(:list_key) { Deferrer::LIST_KEY }
  let(:callback) { lambda { } }

  describe "run" do
    it "processes jobs" do
      expect_any_instance_of(CarDeferrer).to receive(:perform).with(car)
      Deferrer.defer_in(-1, identifier, CarDeferrer, car)
      Deferrer.run(single_run: true)
    end

    it "converts symbols to strings when converting to json and back" do
      expect_any_instance_of(CarDeferrer).to receive(:perform).with({ "a" => "b"})

      Deferrer.defer_in(-1, identifier, CarDeferrer, { a: :b })
      Deferrer.run(single_run: true)
    end

    it "logs info messages if logger provided" do
      expect(Logger).to receive(:info).with("Executing: deferred:#{identifier}")
      Deferrer.defer_in(-1, identifier, CarDeferrer, car)
      Deferrer.run(single_run: true, logger: Logger)
    end

    it "logs error messages if logger provided" do
      expect(Logger).to receive(:error).with("Error: RuntimeError: error")
      Deferrer.defer_in(-1, identifier, InvalidDeferrer, car)
      Deferrer.run(single_run: true, logger: Logger)
    end

    it "runs before callback" do
      expect(callback).to receive(:call)
      Deferrer.defer_in(-1, identifier, CarDeferrer, car)
      Deferrer.run(single_run: true, before_each: callback)
    end

    it "runs after callback" do
      expect(callback).to receive(:call)
      Deferrer.defer_in(-1, identifier, CarDeferrer, car)
      Deferrer.run(single_run: true, after_each: callback)
    end
  end

  describe ".defer_at" do
    it "deferrs at given time" do
      Deferrer.defer_at(Time.now, identifier, CarDeferrer, car)

      expect(redis.zrangebyscore(list_key, '-inf', Time.now.to_f, :limit => [0, 1]).first).not_to be_nil
      expect(redis.exists(item_key(identifier))).to be_truthy
    end
  end

  describe ".defer_in" do
    it "defers in given interval" do
      Deferrer.defer_in(1, identifier, CarDeferrer, car)

      expect(redis.zrangebyscore(list_key, '-inf', (Time.now + 1).to_f, :limit => [0, 1]).first).not_to be_nil
      expect(redis.exists(item_key(identifier))).to be_truthy
    end
  end

  describe ".next_item" do
    it "returns the next item" do
      Deferrer.defer_at(Time.now, identifier, CarDeferrer, car)

      item = Deferrer.next_item

      expect(item['class']).to eq(CarDeferrer.to_s)
      expect(item['args']).to eq([car])
    end

    it "returns last update of an item" do
      Deferrer.defer_at(Time.now - 3, identifier, CarDeferrer, car)
      Deferrer.defer_at(Time.now - 2, identifier, CarDeferrer, car2)

      item = Deferrer.next_item

      expect(item['class']).to eq(CarDeferrer.to_s)
      expect(item['args']).to eq([car2])
    end

    it "keep the old score value" do
      Deferrer.defer_at(Time.now - 3, identifier, CarDeferrer, car)
      Deferrer.defer_at(Time.now + 1, identifier, CarDeferrer, car2)

      expect(Deferrer.next_item).not_to be_nil
    end

    it "returns nil when no next item" do
      expect(Deferrer.next_item).to be_nil
    end

    it "removes values from redis" do
      Deferrer.defer_at(Time.now, identifier, CarDeferrer, car)

      item = Deferrer.next_item

      expect(redis.zrangebyscore(list_key, '-inf', Time.now.to_f, :limit => [0, 1]).first).to be_nil
      expect(redis.exists(item_key(identifier))).to be_falsey
      expect(Deferrer.next_item).to be_nil
    end

    it "doesn't block on empty lists" do
      Deferrer.defer_in(-1, identifier, CarDeferrer, car)
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
      expect_any_instance_of(CarDeferrer).to receive(:perform).with({ "a" => "b"})

      Deferrer.defer_in(-1, identifier, CarDeferrer, { a: :b })
    end
  end
end
