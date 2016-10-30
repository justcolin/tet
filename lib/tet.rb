# Copyright (C) 2016 Colin Fulton
# All rights reserved.
#
# This software may be modified and distributed under the
# terms of the three-clause BSD license. See LICENSE.txt
# (located in root directory of this project) for details.

# Label all tests within a block.
def group name = nil
  before = Tet.test_count

  Tet.in_group(name) { yield }
     .tap { Tet.fail "EMPTY GROUP" if Tet.test_count == before }
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
  PassChar  = "."
  FailChar  = "F"
  ErrorChar = "!"
  Indent    = "    "

  @messages      = []
  @current_group = []
  @test_count    = 0
  @fail_count    = 0
  @err_count     = 0

  class << self
    attr_reader :messages, :test_count, :fail_count, :err_count

    # Store the group name for the duration of calling the given block.
    def in_group name
      result = nil

      @current_group << name.to_s if name

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

      @test_count += 1
    end

    # Log a failing test.
    def fail *messeges, letter: FailChar
      print letter

      @test_count += 1
      @fail_count += 1

      group   = @current_group.dup
      section = @messages

      until group.empty? || group.first != section[-2]
        group.shift
        section = section.last
      end

      until group.empty?
        section << group.shift << []
        section = section.last
      end

      section.concat(messeges)
    end

    # Log an error.
    def error error_object, *messages
      @err_count += 1
      fail *messages, *format_error(error_object), letter: ErrorChar
    end

    # Log test which raised the wrong error.
    def wrong_error expected:, got:
      fail "EXPECTED: #{expected}", *format_error(got)
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
        input.reject(&:empty?)
             .map { |part| indent(part, amount + 1) }
             .join("\n")
      end
    end

    def plural amount, name
      "#{amount} #{name}#{amount != 1 ? "s" : ""}"
    end
  end

  at_exit { Tet.render_result }
end
