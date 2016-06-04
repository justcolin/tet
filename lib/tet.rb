# Copyright (C) 2016 Colin Fulton
# All rights reserved.
#
# This software may be modified and distributed under the
# terms of the three-clause BSD license. See LICENSE.txt
# (located in root directory of this project) for details.

# Label all tests within a block.
def group name = nil
  Tet.in_group(name) { yield }
end

# Declare that a block will return a truthy value.
# If it doesn't or if it has an error, the test will be logged as failing.
def assert name = nil
  Tet.in_group(name) do
    result = false

    begin
      result = yield

      if result
        Tet.pass
      else
        Tet.fail
      end
    rescue StandardError => error_object
      Tet.error(error_object)
    end

    !!result
  end
end

# Declare that a block will have an error.
# If it doesn't the test will be logged as failing.
def err name = nil, expect: StandardError
  Tet.in_group(name) do
    result = false

    begin
      yield
      Tet.fail
    rescue StandardError => error_object
      if expect >= error_object.class
        result = true
        Tet.pass
      else
        Tet.wrong_error(expected: expect, got: error_object)
      end
    end

    result
  end
end

# A namespace for all of the helper methods.
module Tet
  PassChar       = "."
  FailChar       = "F"
  ErrorChar      = "!"
  GroupSeperator = "  |  "

  @current_group = []
  @fail_messeges = []
  @total_tests   = 0
  @total_fails   = 0
  @total_errs    = 0

  class << self
    attr_reader :total_fails
    attr_reader :total_errs

    # Store the group name for the duration of calling the given block.
    def in_group name
      result = nil
      @current_group.push(name) if name

      begin
        result = yield
      rescue StandardError => error_object
        error error_object, "ERROR IN GROUP"
      end

      @current_group.pop if name
      result
    end

    # Log a passing test.
    def pass
      print PassChar

      @total_tests += 1
    end

    # Log a failing test.
    def fail *messeges, letter: FailChar
      print letter

      @total_tests += 1
      @total_fails += 1

      @fail_messeges << @current_group.join(GroupSeperator) << messeges
    end

    # Log an error.
    def error error_object, *messages
      @total_errs += 1
      fail *messages, *format_error(error_object), letter: ErrorChar
    end

    # Log test which raised the wrong error.
    def wrong_error expected:, got:
      fail "EXPECTED: #{expected}", *format_error(got)
    end

    private

    # Format an error message so #indent will render it properly
    def format_error error_object
      [
        "ERROR: #{error_object.class}",
        ["#{error_object.message}", error_object.backtrace]
      ]
    end

    # Format an array of strings by joining them with \n and indenting nested
    # arrays deeper than their parents.
    def indent input, amount = 0
      case input
      when String
        input.gsub(/^/, "  " * amount)
      when Array
        input.reject(&:empty?)
             .map { |part| indent(part, amount + 1) }
             .join("\n")
      end
    end
  end

  # Print messages for all the failing tests.
  at_exit do
    puts "\n" unless @total_tests == 0

    if @total_fails + @total_errs == 0
      puts "all #{@total_tests} tests passed"
    else
      puts "#{@total_fails} fails including #{@total_errs} errors"
    end

    puts indent(@fail_messeges)
  end
end
