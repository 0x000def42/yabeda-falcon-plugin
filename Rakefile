require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--tag ~integration"
end

RSpec::Core::RakeTask.new(:integration) do |t|
  t.rspec_opts = "--tag integration"
  t.pattern = "spec/integration/**/*_spec.rb"
end

task default: :spec
