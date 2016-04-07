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

  class << self
    # Store the group name for the duration of calling the given block.
    def in_group name
      @current_group.push(name)
      yield.tap { @current_group.pop }
    end

    # Log a passing assertion.
    def pass
      print '.'

      @total_asserts +=1
    end

    # Log a failing assertion.
    def fail *messeges, letter: 'F'
      print letter

      @total_asserts +=1
      @fail_messeges << [@current_group.join('  :  '), *messeges].join("\n")
    end

    # Log an assertion error.
    def error error
      fail format_error(error), letter: '!'
    end

    # Log an assertion which had the wrong error.
    def wrong_error expected:, got:
      fail indent("EXPECTED: #{expected}", 1),
           format_error(got)
    end

    private

    def format_error error
      indent("ERROR: (#{error.class}) #{error.message}", 1) +
        "\n" +
        indent(error.backtrace.join("\n"), 2)
    end

    def indent string, amount = 0
      string.gsub(/(?<=\n|\A)/, '    ' * amount)
    end
  end

  # Print messages for all the failing assertions.
  at_exit do
    puts "\n" unless @total_asserts.zero?
    puts "#{@fail_messeges.size} out of #{@total_asserts} failed"

    @fail_messeges.each do |message|
      puts indent('- ' + message, 1)
    end
  end
end
