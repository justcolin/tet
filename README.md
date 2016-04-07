# Tet: Barely A Ruby Test-Framework

- A couple of features
- Relatively nice looking output
- Nothing else

I wanted a micro test-framework to test a parser for a test-framework-framework that I was writing for fun, thus Tet was born. Tet is a *very* minimal test-framework designed for simple projects.

Does the world need another test-framework? **No**.

Is Tet the product boredom and yak shaving? **Yes**.

## Usage

To use Tet, install the gem and add `require "tet"` to your test files. Run tests by evaluating test files using `ruby`.

### Assertions

There are three assertion methods:

- **#assert** takes a block. If the block returns a _truthy_ value, the test passes. If not, it fails.

  ```ruby
    assert { "this is a String".is_a? String } # Passes
    assert { 1 == 2 } # Fails
    assert { not_a_method } # Fails with an error message
  ```

- **#deny** takes a block. If the block returns a _falsy_ value, the test passes. If not, it fails.

  ```ruby
    deny { "this is a String".is_a? String } # Fails
    deny { 1 == 2 } # Passes
    deny { not_a_method } # Fails with an error message
  ```

- **#err** takes a block. If the block _raises an exception_, the test passes. If not, it fails.

  If you pass in an exception class, **#err** will only pass if the exception raised is an instance of that class or one of its subclasses.

  ```ruby
    err { "this is a String".is_a? String } # Fails
    err { 1 == 2 } # Fails
    err { not_a_method } # Passes

    err(ArgumentError) { not_a_method } # Fails (wrong class)
    err(NameError) { not_a_method } # Passes
  ```

### Groups

If you want to label an assertion, group of assertions or group of groups you can use the **#group** method.

```ruby
  group "a group of tests" do
    group "here are some assertions" do
      assert { "a test" }
      assert { "another test" }
    end

    group "more assertions" do
      assert { "what? another test?" }
    end
  end
```
