# Tet: A Ruby Test Framework _(barely)_

- A couple of features
- Relatively nice looking output
- Nothing else

I wanted a micro test framework to test a parser for a larger test framework that I was writing for fun, thus Tet was born. Tet is a *very* minimal test framework designed for simple projects.

Does the world need another test framework? **No**.

Is Tet the product of boredom and yak shaving? **Yes**.

## Usage

To use Tet, install the gem and add `require "tet"` to your test files. Run tests by evaluating your test files using `ruby`.

### Assertions

There are two assertion methods:

- **#assert** takes a block and a test name. If the block returns a truthy value, the test passes. If not, it fails.

  ```ruby
    # Passes:
    assert('strings are strings') { "this is a String".is_a?(String) }

    # Fails because the block returned a falsy value:
    assert('silly math') { 1 == 2 }

    # Fails because there was an error:
    assert('calling a nonexistent function') { not_a_method }
  ```

- **#error** takes a block, a test name and an expected error class. If the block raises an exception of the given class (or a descendant of that class), the test passes. If not, it fails.

  ```ruby
    # Passes because there was a NameError:
    error('nonexistent methods raise errors', expect: NameError) { not_a_method }

    # Fails because the error wasn't an ArgumentError:
    error('expecting a different error', expect: ArgumentError) { not_a_method }
  ```

### Groups

If you want to label a group of assertions or group of groups you can use the **#group** method.

```ruby
  group "a group of tests" do
    string = "40"

    group "here are some assertions" do
      number = string.to_i

      assert('addition works') { number + 2 == 42 }
      assert('numbers are numbers') { number.is_a?(Numeric) }
    end

    group "more assertions" do
      another_string = string + string

      assert { string.size < another_string.size }
    end
  end
```
