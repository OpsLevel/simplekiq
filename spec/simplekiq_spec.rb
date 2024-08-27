# frozen_string_literal: true

RSpec.describe Simplekiq do
  before do
    stub_const("OrcTest::BasicJob", Class.new)

    stub_const("OrcTest::CallbacksJob", Class.new do
      def on_complete(status, options)
      end

      def on_success(status, options)
      end

      def on_death(status, options)
      end
    end)

    stub_const("OrcTest::CustomBatchCallbacksJob", Class.new do
      def define_custom_batch_callbacks(orchestration_batch)
      end
    end)
  end

  it "has a version number" do
    expect(Simplekiq::VERSION).not_to be nil
  end

  describe ".auto_define_callbacks" do
    let(:batch) { instance_double(Sidekiq::Batch) }
    let(:args) { [1, 2, 3] }
    let(:job) { OrcTest::CallbacksJob.new }

    def call
      Simplekiq.auto_define_callbacks(batch, args: args, job: job)
    end

    it "defines callbacks on the batch for every callback the job defines" do
      expect(batch).to receive(:on).once.ordered.with("death", OrcTest::CallbacksJob, "args" => [1, 2, 3])
      expect(batch).to receive(:on).once.ordered.with("complete", OrcTest::CallbacksJob, "args" => [1, 2, 3])
      expect(batch).to receive(:on).once.ordered.with("success", OrcTest::CallbacksJob, "args" => [1, 2, 3])
      call
    end

    context "when the job does not define the callback methods" do
      let(:job) { OrcTest::BasicJob.new }

      it "does not define any callbacks" do
        expect(batch).not_to receive(:on)
        call
      end
    end

    context "when the job defines custom orchestration callback methods" do
      let(:job) { OrcTest::CustomBatchCallbacksJob.new }

      it "calls define_custom_batch_callbacks" do
        expect(job).to receive(:define_custom_batch_callbacks).once.with(batch)
        call
      end
    end
  end
end
