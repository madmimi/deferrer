require 'spec_helper'

describe Deferrer::Item do

  let(:item_hash) { {'id' => 1, 'class' => 'TestWorker', 'args' => [1, 2]} }
  let(:item_json) { MultiJson.dump(item_hash) }

  it "can create a new" do
    item = Deferrer::Item.new(1, 'TestWorker', [1, 2])
    expect(item.id).to eq(1)
    expect(item.class_name).to eq('TestWorker')
    expect(item.args).to eq([1, 2])
  end

  it "can create new item from json" do
    item = Deferrer::Item.from_json(item_json)

    expect(item.id).to eq(1)
    expect(item.class_name).to eq('TestWorker')
    expect(item.args).to eq([1, 2])
  end

  it "can test if two objects are equal" do
    item1 = Deferrer::Item.new(1, 'TestWorker', [1, 2])
    item2 = Deferrer::Item.from_json(item_json)

    expect(item1).to eq(item2)
  end

  it "can convert to hash" do
    item = Deferrer::Item.new(1, 'TestWorker', [1, 2])
    expect(item.to_hash).to eq(item_hash)
  end

  it "can convert to json" do
    item = Deferrer::Item.new(1, 'TestWorker', [1, 2])
    expect(item.to_json).to eq(item_json)
  end
end
