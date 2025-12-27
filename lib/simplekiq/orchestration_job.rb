# frozen_string_literal: true

require "forwardable"

module Simplekiq
  module OrchestrationJob
    include Sidekiq::Job

    extend Forwardable
    def_delegators :orchestration, :run, :in_parallel
    attr_reader :orchestration

    def perform(*args)
      build_orchestration(*args)
      perform_orchestration(*args)

      # This makes it so that if there is a parent batch which this orchestration is run under, then the layered batches will be:
      # parent_batch( orchestration_batch( batch_of_first_step_of_the_orchestration ) )
      # If there is no parent batch, then it will simply be:
      # orchestration_batch( batch_of_first_step_of_the_orchestration )
      conditionally_within_parent_batch do
        OrchestrationExecutor.execute(args: args, job: self, workflow: orchestration.serialized_workflow, child_job_options: orchestration.child_job_options)
      end
    end

    def workflow_plan(*args)
      perform_orchestration(*args)
      orchestration.serialized_workflow
    end

    private

    def conditionally_within_parent_batch
      if batch
        batch.jobs do
          yield
        end
      else
        yield
      end
    end

    def build_orchestration(*args)
      @orchestration ||= Orchestration.new(
        child_job_options: child_job_options(*args)
      )
    end

    def child_job_options(*args)
      {}
    end
  end
end
