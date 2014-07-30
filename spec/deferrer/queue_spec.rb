require 'spec_helper'

describe Deferrer::Queue do
  let(:queue) { Deferrer::Queue }
  let(:id) { 'some_id' }
  let(:redis) { Deferrer.redis }
  let(:list_key) { Deferrer::Queue::LIST_KEY }

  describe ".push" do
    it "can push items" do
      item1 = Deferrer::Item.new('1', 'TestWorker', [1])
      item2 = Deferrer::Item.new('2', 'TestWorker', [2])

      queue.push(item1, Time.now - 1)
      queue.push(item2, Time.now - 2)

      expect(queue.pop).to eq(item2)
      expect(queue.pop).to eq(item1)
    end
  end

  describe ".pop" do
    it "returns the next item" do
      TestWorker.perform_at(Time.now, id, 'test')

      item = queue.pop

      expect(item.class_name).to eq('TestWorker')
      expect(item.args).to eq(['test'])
    end

    it "returns last update of an item" do
      TestWorker.perform_at(Time.now - 3, id, 'update1')
      TestWorker.perform_at(Time.now - 2, id, 'update2')

      item = queue.pop

      expect(item.class_name).to eq('TestWorker')
      expect(item.args).to eq(['update2'])
    end

    it "returns nil when no next item" do
      expect(queue.pop).to be_nil
    end

    it "removes values from redis" do
      TestWorker.perform_at(Time.now, id, 'test')

      item = queue.pop

      expect(redis.zrangebyscore(list_key, '-inf', Time.now.to_f, :limit => [0, 1]).first).to be_nil
      expect(redis.exists(item_key(id))).to be_falsey
      expect(queue.pop).to be_nil
    end

    it "doesn't block on empty lists" do
      TestWorker.perform_in(-1, id, 'test')
      redis.del(item_key(id))

      expect(queue.pop).to be_nil
      expect(redis.zrangebyscore(list_key, '-inf', 'inf', :limit => [0, 1]).first).to be_nil
    end
  end

  describe ".find_by_id" do
    it "can find by id" do
      item1 = Deferrer::Item.new('1', 'TestWorker', [1])
      item2 = Deferrer::Item.new('2', 'TestWorker', [2])

      queue.push(item1, Time.now)
      queue.push(item2, Time.now)

      expect(queue.find_by_id(item1.id)).to eq(item1)
      expect(queue.find_by_id(item2.id)).to eq(item2)
    end
  end

  describe ".find" do
    it "can find by key" do
      item1 = Deferrer::Item.new('1', 'TestWorker', [1])
      item2 = Deferrer::Item.new('2', 'TestWorker', [2])

      queue.push(item1, Time.now)
      queue.push(item2, Time.now)

      expect(queue.find(item_key(item1.id))).to eq(item1)
      expect(queue.find(item_key(item2.id))).to eq(item2)
    end
  end
end
