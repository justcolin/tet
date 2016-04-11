# Copyright (C) 2016 Colin Fulton
# All rights reserved.
#
# This software may be modified and distributed under the
# terms of the three-clause BSD license. See LICENSE.txt
# (located in root directory of this project) for details.

require_relative './tet'

puts 'EXPECTED Results:'
puts '.....F!F!FF.F......F.F.F.!'
puts '11 out of 26 failed'
puts "\nACTUAL Results:"

group 'Passing' do
  group '#assert' do
    group 'truthy blocks pass' do
      assert { 'this is truthy' }
    end
  end

  group '#deny' do
    group 'falsy blocks pass' do
      deny { nil }
    end
  end

  group '#err' do
    group 'passes when there is an error' do
      err { not_a_method }
    end

    group 'allows you to specify an exception class' do
      err(NameError) { not_a_method }
    end

    group 'allows you to specify a parent exception class' do
      err(Exception) { not_a_method }
    end
  end
end

group 'Failing' do
  group '#assert' do
    group 'falsy blocks fail' do
      assert { nil }
    end

    group 'errors are caught and count as failures' do
      assert { not_a_method }
    end
  end

  group '#deny' do
    group 'truthy blocks fail' do
      deny { 'this is truthy' }
    end

    group 'errors are caught and count as failures' do
      deny { not_a_method }
    end
  end

  group '#err' do
    group 'fails when there is no error' do
      err { 1 + 1 }
    end

    group 'fails given wrong error class' do
      err(ArgumentError) { not_a_method }
    end
  end
end

group 'Output' do
  group '#group' do
    group 'returns output of block' do
      assert do
        group('EXAMPLE') {'example ouput'} == 'example ouput'
      end
    end

    group 'this test fails to see what giving a Class as name looks like' do
      group String do
        assert { false }
      end
    end
  end

  # Test if the output of a block is a given Class.
  # Wraps the block in a group to label it as an example instead of a real test.
  def output_is_a? klass
    result = nil

    group('EXAMPLE') { result = yield }

    result.is_a?(klass)
  end

  group 'passing returns true' do
    group '#assert' do
      assert do
        output_is_a?(TrueClass) { assert {"this passes"} }
      end
    end

    group '#deny' do
      assert do
        output_is_a?(TrueClass) { deny {nil} }
      end
    end

    group '#err' do
      assert do
        output_is_a?(TrueClass) { err {not_a_method} }
      end
    end
  end

  group 'failing returns false' do
    group '#assert' do
      assert do
        output_is_a?(FalseClass) { assert {nil} }
      end
    end

    group '#deny' do
      assert do
        output_is_a?(FalseClass) { deny {"this fails"} }
      end
    end

    group '#err' do
      assert do
        output_is_a?(FalseClass) { err {"this fails"} }
      end
    end
  end

  group '"Did you mean?" messages look nice' do
    assert { 1.to_ss }
  end
end
