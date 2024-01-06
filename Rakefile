# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "rake/extensiontask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

spec = Gem::Specification.load("mlir.gemspec")

Rake::ExtensionTask.new "mlir", spec do |ext|
  ext.lib_dir = "lib/mlir"
end

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[test rubocop:autocorrect]
