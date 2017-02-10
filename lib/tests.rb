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

  result = assert { true }
  assert("passing returns true") { result.equal?(true) }

  result = should_fail { assert { false } }
  assert("failing returns false") { result.equal?(false) }

  should_fail do
    assert("falsy blocks fail")     { nil }
    assert("empty assertions fail") { }
  end

  should_err do
    assert("errors are caught and count as failures") { not_a_method }
  end
end

group "#group" do
  expected = "example output"
  result   = group("EXAMPLE") do
               assert("EXAMPLE") { true }
               expected
             end
  assert("returns output of block") { result == expected }

  return_value = should_err { group { raise "Example Error" } }
  assert("returns nil when the block throws an error") { return_value.nil? }

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
  err("passes when there is an error") { not_a_method }

  err("specify an exception class",       expect: NameError) { not_a_method }
  err("specify a parent exception class", expect: Exception) { not_a_method }

  result = err { not_a_method }
  assert("passing returns true") { result.equal?(true) }

  result = should_fail { err { 1 + 1 } }
  assert("failing returns false") { result.equal?(false) }

  should_fail do
    err("no errors fails") { 1 + 1 }
    err("empty assertions fail") { }
    err("wrong class fails", expect: ArgumentError) { not_a_method }

  end
end
