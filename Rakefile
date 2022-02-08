# frozen_string_literal: true

GEMSPEC = File.expand_path('prawn-templates.gemspec', __dir__)
require 'prawn/dev/tasks'

task default: %i[spec rubocop]

desc 'Run all rspec files'
RSpec::Core::RakeTask.new('spec') do |c|
  c.rspec_opts = '-t ~unresolved'
end

RuboCop::RakeTask.new
