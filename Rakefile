# frozen_string_literal: true

require "rspec/core/rake_task"

FileList["tasks/*.rake"].each { |task| load task }

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :test do
  desc "Test against Sidekiq 8.0 (default)"
  task :sidekiq8 do
    sh "bundle install"
    sh "bundle exec rspec"
  end

  desc "Test against Sidekiq 7.3"
  task :sidekiq7 do
    sh "bundle install --gemfile=Gemfile.sidekiq7"
    sh "bundle exec rspec"
  end

  desc "Test against all Sidekiq versions"
  task :all => [:sidekiq8, :sidekiq7]
end
