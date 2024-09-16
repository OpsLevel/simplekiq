# frozen_string_literal: true

RSpec.describe Simplekiq::OrchestrationExecutor do
  let(:workflow) do
    [
      {"klass" => "OrcTest::JobA", "args" => [1]}
    ]
  end

  let!(:job) do
    stub_const("FakeOrchestration", Class.new do
      def on_success(status, options)
      end
    end)

    FakeOrchestration.new
  end

  before { stub_const("OrcTest::JobA", Class.new do
    class << self
      def set(options)
        self
      end
    end
  end) }

  describe ".execute" do
    def execute
      described_class.execute(args: [{ "some" => "args" }], job: job, workflow: workflow)
    end

    it "kicks off the first step with a new batch" do
      batch_double = instance_double(Sidekiq::Batch, bid: 42)
      allow(Sidekiq::Batch).to receive(:new).and_return(batch_double)
      expect(batch_double).to receive(:description=).with("[Simplekiq] FakeOrchestration. Params: [{\"some\"=>\"args\"}]")
      expect(batch_double).to receive(:on).with("success", FakeOrchestration, "args" =>  [{ "some" => "args" }])

      batch_stack_depth = 0 # to keep track of how deeply nested within batches we are
      expect(batch_double).to receive(:jobs) do |&block|
        batch_stack_depth += 1
        block.call
        batch_stack_depth -= 1
      end

      instance = instance_double(Simplekiq::OrchestrationExecutor)
      allow(Simplekiq::OrchestrationExecutor).to receive(:new).and_return(instance)
      expect(instance).to receive(:run_step) do |workflow_arg, step|
        expect(batch_stack_depth).to eq 1
        expect(step).to eq 0
      end

      execute
    end
  end

  describe "run_step" do
    let(:step_batch) { instance_double(Sidekiq::Batch, bid: 42) }
    let(:step) { 0 }
    let(:instance) { described_class.new }

    it "runs the next job within a new step batch" do
      batch_stack_depth = 0 # to keep track of how deeply nested within batches we are
      expect(step_batch).to receive(:jobs) do |&block|
        batch_stack_depth += 1
        block.call
        batch_stack_depth -= 1
      end

      expect(OrcTest::JobA).to receive(:perform_async) do |arg|
        expect(batch_stack_depth).to eq 1
        expect(arg).to eq 1
      end

      allow(Sidekiq::Batch).to receive(:new).and_return(step_batch)
      expect(step_batch).to receive(:on).with("success", described_class, {
        "orchestration_workflow" => workflow,
        "step" => 1,
        "orchestration_job_class_name" => "FakeOrchestration",
      })
      expect(step_batch).to receive(:description=).with("[Simplekiq] step 1 in FakeOrchestration. Running OrcTest::JobA.")

      instance.run_step(workflow, 0, "FakeOrchestration")
    end
  end
end
