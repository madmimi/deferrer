require 'spec_helper'

describe Deferrer::Processor do
  it "can process item" do
    expect_any_instance_of(TestWorker).to receive(:perform).with(1, 2)
    item = Deferrer::Item.new(1, 'TestWorker', [1, 2])
    Deferrer::Processor.new(item).process
  end
end
