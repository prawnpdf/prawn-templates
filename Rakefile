require "bundler"
Bundler.setup

require 'rake'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task :default => [:spec, :rubocop]

desc "Run all rspec files"
RSpec::Core::RakeTask.new("spec") do |c|
  c.rspec_opts = "-t ~unresolved"
end

RuboCop::RakeTask.new
