# Copyright (C) 2016 Colin Fulton
# All rights reserved.
#
# This software may be modified and distributed under the
# terms of the three-clause BSD license. See LICENSE.txt
# (located in root directory of this project) for details.

require_relative "./tet"

$missed_fails   = 0
$missed_errs    = 0
$expected_fails = 0
$expected_errs  = 0

at_exit do
  puts <<~END
    \n
    #{$missed_fails} missed fails
    #{$missed_errs} missed errs
    #{total_fails - $expected_fails + $missed_fails} unintended fails
    #{total_errs - $expected_errs + $missed_errs} unintended errs
  END
end

def total_fails
  Tet.total_fails - Tet.total_errs
end

def total_errs
  Tet.total_errs
end

# Wraps the block in a group to label it as an example instead of a real test.
def should_fail
  $expected_fails += 1
  prev_fail_count  = total_fails
  result           = false

  group("INTENDED FAILURE") { result = yield }

  $missed_fails += 1 if prev_fail_count == total_fails

  result
end

# Wraps the block in a group to label it as an example instead of a real test.
def should_err
  $expected_errs += 1
  prev_err_count  = total_errs
  result          = false

  group("INTENDED ERROR") { result = yield }

  $missed_errs += 1 if prev_err_count == total_errs

  result
end

group "#assert" do
  assert("truthy blocks pass") { true }

  should_fail { assert("falsy blocks fail") { nil } }
  should_err { assert("errors are caught and count as failures") { not_a_method } }

  assert("passing returns true") { true }.equal?(true)

  should_fail { assert("failing returns false") { nil }.equal?(false) }
  should_fail { assert("Can have a name") { nil } }
end

group "#group" do
  assert "returns output of block" do
    group("EXAMPLE") { "example ouput" } == "example ouput"
  end

  return_value = should_err { group { raise "Example Error" } }

  assert "returns nil when the block throws an error" do
    return_value.nil?
  end

  group "can have classes for names" do
    group String do
      should_fail { assert { false } }
    end
  end
end

group "#err" do
  group "passes when there is an error" do
    err { not_a_method }

    assert "... and returns true" do
      err { not_a_method }.equal?(true)
    end
  end

  group "allows you to specify an exception class" do
    err(expect: NameError) { not_a_method }

    group "... or a parent exception class" do
      err(expect: Exception) { not_a_method }
    end

    assert "... and returns true" do
      err(expect: NameError) { not_a_method }.equal?(true)
    end
  end

  group "fails when there is no error" do
    should_fail { err { 1+1 } }

    assert "... and returns false" do
      should_fail { err { 1+1 } }.equal?(false)
    end
  end

  group "ail sgiven wrong error class" do
    should_fail { err(expect: ArgumentError) { not_a_method } }

    assert "... and returns false" do
      should_fail { err(expect: ArgumentError) { not_a_method } }.equal?(false)
    end
  end

  should_fail { err("Can have a name") { 1+1 } }
end
