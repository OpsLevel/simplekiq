# frozen_string_literal: true

module Simplekiq
  class OrchestrationExecutor
    def self.execute(args:, job:, workflow:)
      orchestration_batch = Sidekiq::Batch.new
      orchestration_batch.description = "[Simplekiq] #{job.class.name}. Params: #{args}"
      Simplekiq.auto_define_callbacks(orchestration_batch, args: args, job: job)

      orchestration_batch.jobs do
        new.run_step(workflow, 0, job.class.name) unless workflow.empty?
      end
    end

    def run_step(workflow, step, orchestration_job_class_name)
      *jobs = workflow.at(step)
      # This will never be empty because Orchestration#serialized_workflow skips inserting
      # a new step for in_parallel if there were no inner jobs specified.

      next_step = step + 1
      step_batch = Sidekiq::Batch.new
      step_batch.description = step_batch_description(jobs, next_step, orchestration_job_class_name)
      step_batch.on(
        "success",
        self.class,
        {
          "orchestration_workflow" => workflow,
          "step" => next_step,
          "orchestration_job_class_name" => orchestration_job_class_name,
        }
      )

      step_batch.jobs do
        jobs.each do |job|
          Object.const_get(job["klass"]).set(job["opts"]).perform_async(*job["args"])
        end
      end
    end

    def on_success(status, options)
      return if options["step"] == options["orchestration_workflow"].length

      Sidekiq::Batch.new(status.parent_bid).jobs do
        run_step(options["orchestration_workflow"], options["step"], options["orchestration_job_class_name"])
      end
    end

    private

    def step_batch_description(jobs, step, orchestration_job_class_name)
      description = "[Simplekiq] step #{step} in #{orchestration_job_class_name}. "
      if jobs.length > 1
        description += "Running #{jobs.length} jobs in parallel."
      else
        description += "Running #{jobs[0]["klass"]}."
      end

      description
    end
  end
end
