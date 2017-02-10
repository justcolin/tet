# Copyright (C) 2016 Colin Fulton
# All rights reserved.
#
# This software may be modified and distributed under the
# terms of the three-clause BSD license. See LICENSE.txt
# (located in root directory of this project) for details.

# Label all tests within a block.
def group name = nil
  before = Tet.test_count

  Tet.in_group(name) do
    yield.tap do
      if Tet.test_count == before
        Tet.log_fail("EMPTY GROUP")
      end
    end
  end
end

# Declare that a block will return a truthy value.
# If it doesn't or if it has an error, the test will be logged as failing.
def assert name = nil
    Tet.in_group(name) do
      result = false

      Tet.stop_nesting("NESTED IN ASSERT: #{name}") do
        begin
          result = yield

          if result
            Tet.log_pass
          else
            Tet.log_fail
          end
        rescue StandardError => error_object
          Tet.log_error(error_object)
        end
      end

      !!result
    end
end

# Declare that a block will have an error.
# If it doesn't the test will be logged as failing.
def err name = nil, expect: StandardError
  Tet.in_group(name) do
    result = false

    Tet.stop_nesting("NESTED IN ERR: #{name}") do
      begin
        yield
        Tet.log_fail
      rescue StandardError => error_object
        if expect >= error_object.class
          result = true
          Tet.log_pass
        else
          Tet.log_wrong_error(expected: expect, got: error_object)
        end
      end
    end

    result
  end
end

# A namespace for all of the helper methods.
module Tet
  PassChar  = "."
  FailChar  = "F"
  ErrorChar = "!"
  Indent    = "    "

  @messages      = []
  @current_group = []
  @test_count    = 0
  @fail_count    = 0
  @err_count     = 0
  @nested_ban    = false

  class << self
    attr_reader :messages, :test_count, :fail_count, :err_count

    # Store the group name for the duration of calling the given block.
    def in_group name
      result = nil

      @current_group << name.to_s if name

      begin
        if @nested_ban
          log_fail @nested_ban
        else
          result = yield
        end
      rescue StandardError => error_object
        log_error error_object, "ERROR IN GROUP"
      end

      @current_group.pop if name

      result
    end

    def stop_nesting message
      @nested_ban = message
      yield
      @nested_ban = false
    end

    # Log a passing test.
    def log_pass
      print_now PassChar

      @test_count += 1
    end

    # Log a failing test.
    def log_fail *messages, letter: FailChar
      print_now letter

      @test_count += 1
      @fail_count += 1

      group           = @current_group.dup
      current_section = @messages

      # Walk down the tree of messages until either you find the current group's
      # array of messages OR the last section in common with the current group.
      until group.empty? || group.first != current_section[-2]
        group.shift
        current_section = current_section.last
      end

      # If the messages were missing parts of this group fill out the remaining
      # group names.
      until group.empty?
        current_section << group.shift << []
        current_section = current_section.last
      end

      # Append the new messages onto the current section.
      current_section.concat(messages)
    end

    # Log an error.
    def log_error error_object, *messages
      @err_count += 1
      log_fail *messages, *format_error(error_object), letter: ErrorChar
    end

    # Log test which raised the wrong error.
    def log_wrong_error expected:, got:
      log_fail "EXPECTED: #{expected}", *format_error(got)
    end

    # Print stats and messages for all the failing tests.
    def render_result
      puts "\n" unless @test_count.zero?

      print "#{plural @test_count, 'result'}, "

      if (@fail_count + @err_count).zero?
        print "all good!"
      else
        print "#{plural @fail_count, 'fail'}"
        print " (including #{plural @err_count, 'error'})" unless @err_count.zero?
      end

      print "\n"

      unless @messages.empty?
        puts "\nFailed tests:"
        puts indent(@messages)
      end
    end

    private

    # Format an error message so #indent will render it properly
    def format_error error_object
      [
        "ERROR: #{error_object.class}",
        [
          "#{error_object.message}",
          error_object.backtrace
        ]
      ]
    end

    # Format an array of strings by joining them with \n and indenting nested
    # arrays deeper than their parents.
    def indent input, amount = 0
      case input
      when String
        input.gsub(/^/, Indent * amount)
      when Array
        input
          .reject(&:empty?)
          .map { |part| indent(part, amount + 1) }
          .join("\n")
      end
    end

    # Pluralize the given word.
    def plural amount, word
      "#{amount} #{word}#{amount != 1 ? "s" : ""}"
    end

    # Prevent delays in printing results.
    def print_now string
      print string
      $stdout.flush
    end
  end

  at_exit { Tet.render_result }
end
