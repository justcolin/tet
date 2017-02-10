# Copyright (C) 2017 Colin Fulton
# All rights reserved.
#
# This software may be modified and distributed under the
# terms of the three-clause BSD license. See LICENSE.txt
# (located in root directory of this project) for details.

$missed_fails   = 0
$missed_errs    = 0
$expected_fails = 0
$expected_errs  = 0

at_exit do
  puts <<~END

    #{$missed_fails} missed fails
    #{$missed_errs} missed errs
    #{total_fails - $expected_fails + $missed_fails} unintended fails
    #{total_errs - $expected_errs + $missed_errs} unintended errs
  END
end

def total_fails
  Tet.fail_count - Tet.err_count
end

def total_errs
  Tet.err_count
end

# Wraps the block in a group to label it as an example instead of a real test.
def should_fail
  prev_test_count = Tet.test_count
  prev_fail_count = total_fails
  result          = false

  group("INTENDED FAILURES") { result = yield }


  $expected_fails += Tet.test_count - prev_test_count
  $missed_fails   += 1 if prev_fail_count == total_fails

  result
end

# Wraps the block in a group to label it as an example instead of a real test.
def should_err
  $expected_errs += 1
  prev_err_count  = total_errs
  result          = false

  group("INTENDED ERRORS") { result = yield }

  $missed_errs += 1 if prev_err_count == total_errs

  result
end
