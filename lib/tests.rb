# Copyright (C) 2017 Colin Fulton
# All rights reserved.
#
# This software may be modified and distributed under the
# terms of the three-clause BSD license. See LICENSE.txt
# (located in root directory of this project) for details.

require_relative './tet'

SHOW_EXPECTED = false

def prefix string
  if SHOW_EXPECTED
    TetCore.break_after_print
    print string
  end
end

def pass; prefix 'PASS  = '; end
def fail; prefix 'FAIL  = '; end
def err;  prefix 'ERROR = '; end

def test_between
  assert('Intentional failure') { false }
  yield
  assert('') { true }
  yield
  assert('Intentional failure') { false }
end

class IntendedError < StandardError; end

group('#assert') do
  pass; assert('True assertions pass') { true }
  fail; assert('False assertions fail') { false }
  err; assert('Errors are caught') { raise IntendedError.new('error message') }

  puts 'Multiple passes in a row show on one line:'
  assert('') { true }
  assert('') { true }
  assert('') { true }
end

group('#group') do
  group('Can nest') do
    fail; assert('Intentional failure') { false }
  end

  group('Can have classes as names') do
    group(String) do
      fail; assert('Intentional failure') { false }
    end
  end
end

group('#error') do
  fail; error('True errors fail', expect: StandardError) { true }
  fail; error('False errors fail', expect: StandardError) { false }

  err; error('Unexpected errors err', expect: NoMethodError) do
    raise IntendedError.new('should expect different error')
  end

  pass; error('Expected errors pass', expect: IntendedError) do
    raise IntendedError.new('SHOULD NOT BE SEEN')
  end
end

puts
puts "Testing #puts between different results:"
test_between { puts 'Test of #puts' }

puts
puts "Testing #p between different results:"
test_between { p 'Test of #p' }
