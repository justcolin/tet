# Copyright (C) 2016 Colin Fulton
# All rights reserved.
#
# This software may be modified and distributed under the
# terms of the three-clause BSD license. See LICENSE.txt
# (located in root directory of this project) for details.

# Label all tests within a block.
def group name
  Tet.in_group(name) { yield }
end

# Declare that a block will return a truthy value.
# If it doesn't or if it has an error, the assertion will be logged as failing.
def assert
  result = false

  begin
    result = yield

    if result
      Tet.pass
    else
      Tet.fail
    end
  rescue StandardError => error
    Tet.error(error)
  end

  !!result
end

# Declare that a block will return a falsy value.
# If it doesn't or if it has an error, the assertion will be logged as failing.
def deny
  assert { !yield }
end

# Declare that a block will have an error.
# If it doesn't the assertion will be logged as failing.
def err expect = StandardError
  result = false

  begin
    yield
    Tet.fail
  rescue StandardError => error
    if expect >= error.class
      result = true
      Tet.pass
    else
      Tet.wrong_error(expected: expect, got: error)
    end
  end

  result
end

# A namespace for all of the helper methods.
module Tet
  @current_group = []
  @fail_messeges = []
  @total_asserts = 0
  @total_fails   = 0

  class << self
    # Store the group name for the duration of calling the given block.
    def in_group name
      @current_group.push(name)
      yield.tap { @current_group.pop }
    end

    # Log a passing assertion.
    def pass
      print '.'

      @total_asserts += 1
    end

    # Log a failing assertion.
    def fail *messeges, letter: 'F'
      print letter

      @total_asserts += 1
      @total_fails   += 1
      @fail_messeges << @current_group.join('  :  ') << messeges
    end

    # Log an assertion error.
    def error error
      fail *format_error(error), letter: '!'
    end

    # Log an assertion which had the wrong error.
    def wrong_error expected:, got:
      fail "EXPECTED: #{expected}", *format_error(got)
    end

    private

    def format_error error
      [
        "ERROR: #{error.class}",
        ["#{error.message}", error.backtrace]
      ]
    end

    def indent input, amount = 0
      case input
      when String
        input.gsub(/^/, '  ' * amount)
      when Array
        input.reject(&:empty?)
             .map { |part| indent(part, amount + 1) }
             .join("\n")
      end
    end
  end

  # Print messages for all the failing assertions.
  at_exit do
    puts "\n" unless @total_asserts.zero?
    puts "#{@total_fails} out of #{@total_asserts} failed"
    puts indent(@fail_messeges)
  end
end
