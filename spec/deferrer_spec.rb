require 'spec_helper'

class CarDeferrer
  def self.perform(car)
    car.upcase
  end
end

describe Deferrer do
  let(:car) { 'car' }
  let(:car2) { 'car2' }
  let(:identifier) { 'car1' }
  let(:redis) { Deferrer.redis }
  let(:list_key) { Deferrer::LIST_KEY }

  before :each do
    redis.flushall
  end

  describe ".defer_at" do
    it "deferrs at given time" do
      Deferrer.defer_at(Time.now, identifier, CarDeferrer, car)

      redis.zrangebyscore(list_key, '-inf', Time.now.to_f, :limit => [0, 1]).first.should_not be_nil
      redis.exists(Deferrer.item_key(identifier)).should be_true
    end

    it "deferrs in given interval" do
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
  end
end
