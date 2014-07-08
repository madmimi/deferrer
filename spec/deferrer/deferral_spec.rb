require 'spec_helper'
require 'timeout'

class CarDeferrer
  def self.perform(car)
  end
end

class Logger
  def self.info(message)
  end

  def self.error(message)
  end
end

class InvalidLogger
  def self.error(message)
  end
end

describe Deferrer::Deferral do
  let(:car) { 'car' }
  let(:car2) { 'car2' }
  let(:identifier) { 'car1' }
  let(:redis) { Deferrer.redis }
  let(:list_key) { Deferrer::Deferral::LIST_KEY }

  before :each do
    redis.flushdb
  end

  describe "run" do
    it "processes jobs" do
      CarDeferrer.should_receive(:perform).with(car)
      Deferrer.defer_in(-1, identifier, CarDeferrer, car)
      Deferrer.run(single_run: true)
    end

    it "logs info messages if logger provided" do
      Logger.should_receive(:info).with("Executing: deferred:#{identifier}")
      Deferrer.defer_in(-1, identifier, CarDeferrer, car)
      Deferrer.run(single_run: true, logger: Logger)
    end

    it "logs error messages if logger provided" do
      InvalidLogger.should_receive(:error).with("Error: NoMethodError: undefined method `info' for InvalidLogger:Class")
      Deferrer.defer_in(-1, identifier, CarDeferrer, car)
      Deferrer.run(single_run: true, logger: InvalidLogger)
    end
  end

  describe ".defer_at" do
    it "deferrs at given time" do
      Deferrer.defer_at(Time.now, identifier, CarDeferrer, car)

      redis.zrangebyscore(list_key, '-inf', Time.now.to_f, :limit => [0, 1]).first.should_not be_nil
      redis.exists(Deferrer.item_key(identifier)).should be_true
    end

    it "defers in given interval" do
      Deferrer.defer_in(1, identifier, CarDeferrer, car)

      redis.zrangebyscore(list_key, '-inf', (Time.now + 1).to_f, :limit => [0, 1]).first.should_not be_nil
      redis.exists(Deferrer.item_key(identifier)).should be_true
    end
  end

  describe ".next_item" do
    it "returns the next item" do
      Deferrer.defer_at(Time.now, identifier, CarDeferrer, car)

      item = Deferrer.next_item

      item['class'].should == CarDeferrer.to_s
      item['args'].should == [car]
    end

    it "returns last update of an item" do
      Deferrer.defer_at(Time.now - 3, identifier, CarDeferrer, car)
      Deferrer.defer_at(Time.now - 2, identifier, CarDeferrer, car2)

      item = Deferrer.next_item

      item['class'].should == CarDeferrer.to_s
      item['args'].should == [car2]
    end

    it "keep the old score value" do
      Deferrer.defer_at(Time.now - 3, identifier, CarDeferrer, car)
      Deferrer.defer_at(Time.now + 1, identifier, CarDeferrer, car2)

      Deferrer.next_item.should_not be_nil
    end

    it "returns nil when no next item" do
      Deferrer.next_item.should be_nil
    end

    it "removes values from redis" do
      Deferrer.defer_at(Time.now, identifier, CarDeferrer, car)

      item = Deferrer.next_item

      redis.zrangebyscore(list_key, '-inf', Time.now.to_f, :limit => [0, 1]).first.should be_nil
      redis.exists(Deferrer.item_key(identifier)).should be_false
      Deferrer.next_item.should be_nil
    end

    it "doesn't block on empty lists" do
      Deferrer.defer_in(-1, identifier, CarDeferrer, car)
      redis.del Deferrer.item_key(identifier)

      Timeout::timeout(2) { Deferrer.next_item.should be_nil }
      redis.zrangebyscore(list_key, '-inf', 'inf', :limit => [0, 1]).first.should be_nil
    end
  end
end
