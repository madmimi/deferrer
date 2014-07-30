require 'spec_helper'
require 'logger'

describe Deferrer::Runner do
  let(:id) { 'some_id' }
  let(:logger) { Logger.new(STDOUT) }

  describe ".run" do
    it "processes jobs" do
      expect_any_instance_of(TestWorker).to receive(:perform).with('test')

      TestWorker.defer_in(-1, id, 'test')
      Deferrer.run(single_run: true)
    end

    it "correctly sets arguments and converts symbols to strings for hashes" do
      expect_any_instance_of(TestWorker).to receive(:perform).with(1, 'arg1', { "a" => "b"})

      TestWorker.defer_in(-1, id, 1, 'arg1', { a: :b })
      Deferrer.run(single_run: true)
    end

    it "rescues standard errors" do
      expect(logger).to receive(:error).with("Error: RuntimeError: error")
      expect(Deferrer::Queue).to receive(:pop) { raise RuntimeError.new('error') }

      TestWorker.defer_in(-1, id, 'test')
      Deferrer.logger = logger
      Deferrer.run(single_run: true)
    end

    it "rescues exceptions and logs error messages" do
      expect(logger).to receive(:error).with("Error: Exception: error")
      expect(Deferrer::Queue).to receive(:pop) { raise Exception.new('error') }

      TestWorker.defer_in(-1, id, 'test')
      Deferrer.logger = logger
      expect { Deferrer.run(single_run: true) }.to raise_error(Exception)
    end

    it "ignores time to wait and performs jobs" do
      expect_any_instance_of(TestWorker).to receive(:perform).with({ "c" => "d"})

      TestWorker.defer_in(100, id, { a: :b })
      TestWorker.defer_in(100, id, { c: :d })

      Deferrer.run(single_run: true, ignore_time: true)
    end
  end

  describe ".logger" do
    before :each do
      Deferrer.logger = logger
    end

    it "logs info messages" do
      expect(logger).to receive(:info).with("Processing: #{id}")

      TestWorker.defer_in(-1, id, 'test')
      Deferrer.run(single_run: true)
    end

    it "logs error messages" do
      expect(logger).to receive(:error).with("Error: RuntimeError: error")
      allow(Deferrer::Queue).to receive(:pop) { raise RuntimeError.new('error') }

      TestWorker.defer_in(-1, id, 'test')
      Deferrer.run(single_run: true)
    end

    it "logs error messages on exceptions" do
      expect(logger).to receive(:error).with("Error: Exception: error")
      allow(Deferrer::Queue).to receive(:pop) { raise Exception.new('error') }

      TestWorker.defer_in(-1, id, 'test')
      expect { Deferrer.run(single_run: true) }.to raise_error
    end
  end
end
