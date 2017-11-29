# Copyright (C) 2017 Colin Fulton
# All rights reserved.
#
# This software may be modified and distributed under the
# terms of the three-clause BSD license. See LICENSE.txt
# (located in root directory of this project) for details.

require_relative './tet'


module TetCore
  # Print a prefix before an assertion in block.
  def self.with_prefix prefix
    print prefix
    yield
  ensure
    puts if @previous_passed
    @previous_passed = false
  end
end

WITH_PREFIX = true

def pass
  WITH_PREFIX ? TetCore.with_prefix('PASS > ') { yield } : yield
end

def fail
  WITH_PREFIX ? TetCore.with_prefix('FAIL > ') { yield } : yield
end

def err
  WITH_PREFIX ? TetCore.with_prefix('ERROR > ') { yield } : yield
end

class IntendedError < StandardError; end

group('#assert') do
  pass { assert('True assertions pass') { true } }
  fail { assert('False assertions fail') { false } }
  err { assert('Errors are caught') { raise IntendedError.new('error message') } }
end

group('#group') do
  group('Can nest') do
    fail { assert('Intentional failure') { false } }
  end

  group('Can have classes as names') do
    group(String) do
      fail { assert('Intentional failure') { false } }
    end
  end
end

group('#error') do
  fail { error('True assertions fail') { true } }
  fail { error('False assertions fail') { false } }
  pass { error('Errors pass') { raise IntendedError.new('SHOULD NOT BE SEEN') } }

  err do
    error('Unexpected errors fail', expect: NoMethodError) do
      raise IntendedError.new('should expect different error')
    end
  end

  pass do
    error('Expected errors pass', expect: IntendedError) do
      raise IntendedError.new('SHOULD NOT BE SEEN')
    end
  end
end
