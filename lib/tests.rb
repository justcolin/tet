# Copyright (C) 2017 Colin Fulton
# All rights reserved.
#
# This software may be modified and distributed under the
# terms of the three-clause BSD license. See LICENSE.txt
# (located in root directory of this project) for details.

require_relative './tet'

class IntendedError      < StandardError; end
class IntendedErrorChild < IntendedError; end

puts ".!?!!?!!!!!!.!.??????? (expected result)"

assert('true blocks pass')  { true  }
assert('false blocks fail') { false }

assert('errors are caught') { raise IntendedError }

group '#group' do
  assert('first failure')  { false }
  assert('second failure') { false }

  group('errors are caught') { raise IntendedError }
end

group 'anything can be a label' do
  assert(:a_symbol)    { false }
  assert(Class)        { false }
  assert(Enumerable)   { false }
  assert(true)         { false }
  assert({x: 1, y: 2}) { false }
  assert(nil)          { false }
end

group '#err' do
  err('errors pass')     { raise IntendedError }
  err('non-errors fail') { true }

  err('correct errors pass',   expect: IntendedError)      { raise IntendedError }
  err('incorrect errors err', expect: IntendedErrorChild) { raise IntendedError }
end

group 'should not nest' do
  assert('#assert in #assert') { assert    { true                } }
  assert('#group in #assert')  { group('') { 'empty #group'      } }
  assert('#err in #assert')    { err       { raise IntendedError } }
  err('#assert in #err')       { assert    { true                } }
  err('#group in #err')        { group('') { 'empty #group'      } }
  err('#err in #err')          { err       { raise IntendedError } }
end
