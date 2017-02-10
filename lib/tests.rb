# Copyright (C) 2016 Colin Fulton
# All rights reserved.
#
# This software may be modified and distributed under the
# terms of the three-clause BSD license. See LICENSE.txt
# (located in root directory of this project) for details.

require_relative "./tet"
require_relative "./test_helpers"

group "#assert" do
  assert("truthy blocks pass") { true }

  should_fail { assert("falsy blocks fail") { nil } }
  should_err { assert("errors are caught and count as failures") { not_a_method } }
  should_fail { assert("empty assertions fail") {} }

  assert("passing returns true") {  assert { true }.equal?(true) }

  should_fail { assert("failing returns false") { nil }.equal?(false) }
end

group "#group" do
  assert "returns output of block" do
    result = group("EXAMPLE") do
               assert("EXAMPLE") { true }
               "example output"
             end

      result == "example output"
  end

  return_value = should_err { group { raise "Example Error" } }

  assert "returns nil when the block throws an error" do
    return_value.nil?
  end

  group 'fails when empty' do
    should_fail { group('group without content') { } }
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

    assert "and returns true" do
      err { not_a_method }.equal?(true)
    end
  end

  should_fail { err("empty assertions fail") {} }

  group "allows you to specify an exception class" do
    err(expect: NameError) { not_a_method }

    group "or a parent exception class" do
      err(expect: Exception) { not_a_method }
    end

    assert "and returns true" do
      err(expect: NameError) { not_a_method }.equal?(true)
    end
  end

  group "fails when there is no error" do
    should_fail { err { 1+1 } }

    assert "and returns false" do
      should_fail { err { 1+1 } }.equal?(false)
    end
  end

  group "fails given wrong error class" do
    should_fail { err(expect: ArgumentError) { not_a_method } }

    assert "and returns false" do
      should_fail { err(expect: ArgumentError) { not_a_method } }.equal?(false)
    end
  end

  should_fail { err("Can have a name") { 1+1 } }
end
