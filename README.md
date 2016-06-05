# Tet: A Ruby Test Framework _(barely)_

- A couple of features
- Relatively nice looking output
- Nothing else

I wanted a micro test framework to test a parser for a larger test framework that I was writing for fun, thus `tet` was born. Tet is a *very* minimal test framework designed for simple projects.

Does the world need another test framework? **No**.

Is Tet the product of boredom and yak shaving? **Yes**.

## Usage

To use Tet, install the gem and add `require "tet"` to your test files. Run tests by evaluating your test files using `ruby`.

### Assertions

There are two assertion methods:

- **#assert** takes a block. If the block returns a truthy value, the test passes. If not, it fails.

  ```ruby
    assert { "this is a String".is_a?(String) } # Passes
    assert { 1 == 2 } # Fails becaue the block returned a falsey value
    assert { not_a_method } # Fails because there was an error
  ```

- **#err** takes a block. If the block raises an exception, the test passes. If not, it fails.

  If you pass in an exception class to the `expect` argument the test will only pass if the exception raised within the block is an instance of that class or one of its subclasses.

  ```ruby
    err { 1 == 2 } # Fails because there was no error
    err { not_a_method } # Passes because there was an error

    err(expect: NameError) { not_a_method } # Passes because there was a NameError
    err(expect: ArgumentError) { not_a_method } # Fails the error wasn't an ArgumentError
  ```

Both of these methods optionally take a `name` as the first argument to let you note what the assertion does:

```ruby
  assert("all is right with the world") { 1 == 1 }
  err("no method errors work") { nonexistent_method }
```

### Groups

If you want to label a group of assertions or group of groups you can use the **#group** method.

```ruby
  group "a group of tests" do
    string = "40"

    group "here are some assertions" do
      number = string.to_i

      assert { number + 2 == 42 }
      assert { number.is_a?(Numeric) }
    end

    group "more assertions" do
      another_string = string + string

      assert { string.size < another_string.size }
    end
  end
```
