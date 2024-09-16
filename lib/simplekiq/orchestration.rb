# frozen_string_literal: true

module Simplekiq
  class Orchestration
    attr_accessor :serial_workflow, :parallel_workflow
    def initialize
      @serial_workflow = []
      @job_options = {}
    end

    def with_job_options(**options)
      @job_options = options
      self
    end

    def run(*step)
      workflow = parallel_workflow || serial_workflow
      workflow << step
    end

    def in_parallel
      @parallel_workflow = []
      yield
      serial_workflow << @parallel_workflow if @parallel_workflow.any?
    ensure
      @parallel_workflow = nil
      serial_workflow
    end

    def serialized_workflow
      @serialized_workflow ||= serial_workflow.map do |step|
        case step[0]
        when Array
          step.map do |(job, *args)|
            {"klass" => job.name, "opts" => @job_options, "args" => args}
          end
        when Class
          job, *args = step
          {"klass" => job.name, "opts" => @job_options, "args" => args}
        end
      end
    end
  end
end
