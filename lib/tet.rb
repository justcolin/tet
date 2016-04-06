# Copyright (C) 2016 Colin Fulton
# All rights reserved.
#
# This software may be modified and distributed under the
# terms of the three-clause BSD license. See LICENSE.txt
# (located in root directory of this project) for details.

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


def deny
  assert { !yield }
end


def err expect = StandardError
  result = false

  begin
    yield
    Tet.no_error
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


def group name
  Tet.in_group(name) { yield }
end


module Tet
  @current_group = []
  @fail_messeges = []
  @total_asserts = 0

  class << self
    def in_group name
      @current_group.push(name)
      yield.tap { @current_group.pop }
    end

    def pass
      print '.'

      @total_asserts +=1
    end

    def fail *messeges, letter: 'F'
      print letter

      @total_asserts +=1
      @fail_messeges << [@current_group.join('  :  '), *messeges].join("\n")
    end

    def error error
      fail format_error(error), letter: '!'
    end

    def no_error
      fail indent("EXPECTED AN ERROR", 1)
    end

    def wrong_error expected:, got:
      fail indent("EXPECTED: #{expected}", 1),
           format_error(got)
    end

    private

    def format_error error
      indent("ERROR: (#{error.class}) #{error.message}", 1) +
      indent(error.backtrace.join("\n"), 2)
    end

    def indent string, amount = 0
      string.gsub(/(?<=\n|\A)/, '    ' * amount)
    end
  end

  at_exit do
    puts "\n" unless @total_asserts.zero?
    puts "#{@fail_messeges.size} out of #{@total_asserts} failed"

    @fail_messeges.each do |message|
      puts indent('- ' + message, 1)
    end
  end
end
