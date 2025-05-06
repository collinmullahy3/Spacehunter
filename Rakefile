require 'sinatra/activerecord/rake'
require './app'

namespace :db do
  task :load_config do
    # No additional configuration needed since we set it in app.rb
  end
end

task :default => :console

desc "Start the console"
task :console do
  require 'irb'
  ARGV.clear
  IRB.start
end