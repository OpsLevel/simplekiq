# frozen_string_literal: true

require "sidekiq"
require "sidekiq-pro"

require "simplekiq/orchestration_executor"
require "simplekiq/orchestration"
require "simplekiq/orchestration_job"
require "simplekiq/batching_job"

module Simplekiq
  class << self
    def auto_define_callbacks(batch, args:, job:)
      batch.on("death", job.class, "args" => args) if job.respond_to?(:on_death)
      batch.on("complete", job.class, "args" => args) if job.respond_to?(:on_complete)
      batch.on("success", job.class, "args" => args) if job.respond_to?(:on_success)

      job.define_custom_batch_callbacks(batch) if job.respond_to?(:define_custom_batch_callbacks)
    end
  end
end
