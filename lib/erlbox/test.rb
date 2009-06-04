## -------------------------------------------------------------------
##
## Erlang Toolbox: Included tasks for running tests
## Copyright (c) 2008 The Hive.  All rights reserved.
##
## -------------------------------------------------------------------

# TODO Should look at the test tasks in Rake to get a better idea how
# to structure this...

## -------------------------------------------------------------------
## Constants

UNIT_TEST_FLAGS = []
INT_TEST_FLAGS  = []
PERF_TEST_FLAGS = []

TEST_ROOT = "."
TEST_LOG_DIR = "#{TEST_ROOT}/logs"

UNIT_TEST_DIR = "#{PWD}/#{TEST_ROOT}/test"
INT_TEST_DIR  = "#{PWD}/#{TEST_ROOT}/int_test"
PERF_TEST_DIR = "#{PWD}/#{TEST_ROOT}/perf_test"

CLOBBER.include TEST_LOG_DIR

## -------------------------------------------------------------------
## Tasks

namespace :test do

  desc "Test preparation run before all tests"
  task :prepare do
    fail "No tests defined" unless File.directory?(TEST_ROOT)
    Dir.mkdir(TEST_LOG_DIR) unless File.directory?(TEST_LOG_DIR)

    # Always compile tests with debug info
    puts "Debugging is enabled for test builds."
    ERLC_FLAGS << '+debug_info'
  end

  desc "Show test results in a browser"
  task :results do
    `open #{TEST_LOG_DIR}/index.html`
  end

  ['unit', 'int', 'perf'].each do |type|
    desc "Run #{type} tests"
    task type => "test:#{type}:prepare" do
      check_and_run_tests(type, false)
    end

    namespace type do
      desc "Prepare #{type} tests"
      task :prepare => ['^prepare', 'compile']

      desc "Compile #{type} tests"
      task :compile => 'rake:compile' do
        compile_tests(type)
      end

      desc "Run #{type} tests with coverage"
      task :cover => :prepare do
        check_and_run_tests(type, true)
      end
    end
  end

  desc "Run all tests"
  task :all => [:unit, :int, :perf]

end

task :test => 'test:unit'
task :int_test => 'test:int'
task :perf_test => 'test:perf'

## -------------------------------------------------------------------
## Helpers

def test_dir(type)
  eval("#{type.to_s.upcase}_TEST_DIR")
end

def compile_tests(type)
  # Is this necessary? I don't think so since CT compiles code itself.
  # TODO Either need to get rid of this or turn it into an actual task
  dir = test_dir(type)
  if File.directory?(dir)
    compile_cmd = "erlc -I#{erl_where('common_test')} -I#{erl_where('test_server')}\
                        #{print_flags(ERLC_FLAGS)} #{expand_path(ERL_PATH)}\
                        -o #{dir} #{dir}/*.erl"

    sh compile_cmd
  end
end

def check_and_run_tests(type, use_cover = false)
  dir = test_dir(type)
  if File.directory?(dir)
    run_tests(dir, use_cover, print_flags(eval("#{type.upcase}_TEST_FLAGS")))
  else
    puts "No #{type} tests defined. Skipping."
  end
end

def run_tests(dir, cover = false, rest = "")
  puts "running tests in #{dir}#{' with coverage' if cover}..."

  config_flags = ""
  if File.exists?("#{dir}/test.config")
    config_flags << "-ct_config #{dir}/test.config"
  end

  if File.exists?("#{dir}/app.config")
    config_flags << " -config #{dir}/app.config"
  end

  cmd = "erl #{expand_path(ERL_PATH)} -pa #{PWD}/ebin #{PWD}/include\
             -noshell\
             -s ct_run script_start\
             -s erlang halt\
             -name test@#{`hostname`.strip}\
             #{cover_flags(dir, cover)}\
             #{get_suites(dir)}\
             -logdir #{TEST_LOG_DIR}\
             -env TEST_DIR #{dir}\
             #{config_flags} #{rest}"

  if !defined?(NOISY_TESTS) && !verbose?
    output = `#{cmd}`

    fail if $?.exitstatus != 0 && !ENV["stop_on_fail"].nil?

    File.open("#{PWD}/#{TEST_LOG_DIR}/raw.log", "w") do |file|
      file.write "--- Test run on #{Time.now.to_s} ---\n"
      file.write output
      file.write "\n\n"
    end

    if output[/, 0 failed/]
      puts "==> " + output[/TEST COMPLETE,.*test cases$/]
    else
      puts output
    end
  else
    puts cmd.squeeze(' ')
    sh cmd
  end
end

def cover_flags(dir, use_cover)
  use_cover ? "-cover #{dir}/cover.spec" : ""
end

def get_suites(dir)
  suites = ENV['suites']
  if suites
    all_suites = ""
    suites.each(' ') {|s| all_suites << "#{dir}/#{s.strip}_SUITE "}
    "-suite #{all_suites}"
  else
    "-dir #{dir}"
  end
end
