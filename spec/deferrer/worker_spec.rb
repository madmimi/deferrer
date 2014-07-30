require 'spec_helper'

describe Deferrer::Worker do
  let(:id) { 'some_id' }
  let(:redis) { Deferrer.redis }
  let(:list_key) { Deferrer::Queue::LIST_KEY }

  describe ".perform_at" do
    it "deferrs at given time" do
      TestWorker.perform_at(Time.now, id, 'test')

      expect(redis.zrangebyscore(list_key, '-inf', Time.now.to_f, :limit => [0, 1]).first).not_to be_nil
      expect(redis.exists(item_key(id))).to be_truthy
    end
  end

  describe ".perform_in" do
    it "defers in given interval" do
      TestWorker.perform_in(1, id, 'test')

      expect(redis.zrangebyscore(list_key, '-inf', (Time.now + 1).to_f, :limit => [0, 1]).first).not_to be_nil
      expect(redis.exists(item_key(id))).to be_truthy
    end
  end

  describe ".inline" do
    it "ignores time to wait and performs jobs" do
      Deferrer.inline = true
      expect_any_instance_of(TestWorker).to receive(:perform).with({ "c" => "d"})

      TestWorker.perform_in(100, id, { c: :d })
    end
  end
end
