# Copyright (C) 2016 Colin Fulton
# All rights reserved.
#
# This software may be modified and distributed under the
# terms of the three-clause BSD license. See LICENSE.txt
# (located in root directory of this project) for details.

require_relative "./tet"

puts <<-END
Expected results:
.F!..F.F.F!..F.F.!.F.......FF.FF.F!
16 out of 35 failed

Actual results:
END

# Wraps the block in a group to label it as an example instead of a real test.
def fails
  group("INTENDED FAILURE") { result = yield }
end

group "#assert" do
  assert("truthy blocks pass") { true }

  fails do
    assert("falsy blocks fail") { nil }
    assert("errors are caught and count as failures") { not_a_method }
  end

  assert "passing returns true" do
    assert { true }.equal?(true)
  end

  assert "failing returns false" do
    fails { assert { nil }.equal?(false) }
  end

  fails { assert("Can have a name") { nil } }
end

group "#deny" do
  deny("falsey blocks pass") { nil }

  fails do
    deny("truthy blocks fail") { :truthy }
    deny("errors are caught and count as failures") { not_a_method }
  end

  assert "passing returns true" do
    deny { nil }.equal?(true)
  end

  assert "failing returns false" do
    fails { deny { :truthy }.equal?(false) }
  end

  fails { deny("Can have a name") { :truthy } }
end

group "#group" do
  assert "returns output of block" do
    group("EXAMPLE") { "example ouput" } == "example ouput"
  end

  return_value = fails { group("catches errors") { raise "Example Error" } }

  assert "returns nil when an assertion returns an error" do
    return_value.nil?
  end

  group "can have classes for names" do
    group String do
      fails { assert { false } }
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
    fails { err { 1+1 } }

    assert "... and returns false" do
      fails { err { 1+1 } }.equal?(false)
    end
  end

  group "fails given wrong error class" do
    fails { err(expect: ArgumentError) { not_a_method } }

    assert "... and returns false" do
      fails { err(expect: ArgumentError) { not_a_method } }.equal?(false)
    end
  end

  fails { err("Can have a name") { 1+1 } }
end

group "'Did you mean?' error messages look nice" do
  fails { assert { 1.to_z } }
end
