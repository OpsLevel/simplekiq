# frozen_string_literal: true

module Simplekiq
  class Orchestration
    attr_accessor :serial_workflow, :parallel_workflow
    attr_reader :child_job_options

    def initialize(child_job_options: {})
      @serial_workflow = []
      @child_job_options = child_job_options
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
            {"klass" => job.name, "opts" => @child_job_options, "args" => args}
          end
        when Class
          job, *args = step
          {"klass" => job.name, "opts" => @child_job_options, "args" => args}
        end
      end
    end
  end
end
