# Copyright (C) 2017 Colin Fulton
# All rights reserved.
#
# This software may be modified and distributed under the
# terms of the three-clause BSD license. See LICENSE.txt
# (located in root directory of this project) for details.

module TetCore
  INDENT_DEPTH = 4
  SEPERATOR    = '  |  '
  FAIL_HEADER  = 'FAIL:  '
  ERROR_HEADER = 'ERROR: '

  @prev_printed = false
  @messages     = []
  @counts       = Struct.new(:tests, :fails, :errors)
                        .new(0,      0,      0)

  # Output totals at the end of the test run.
  at_exit do
    puts "\nTests: #{@counts.tests}   Fails: #{@counts.fails}   Errors: #{@counts.errors}"
  end

  class << self
    # Record an assertion.
    def assert
      @counts.tests += 1
    end

    # Record a passing assertion.
    def pass
      checked_print ?.
    end

    # Record a failing assertion.
    def fail
      @counts.fails += 1
      puts_failure_data(header: FAIL_HEADER)
    end

    # Run a block under a certain name, catching and printing errors.
    def group name
      @messages << name
      yield
    rescue StandardError => caught
      @counts.errors += 1
      puts_failure_data(
        header:          ERROR_HEADER,
        additional_info: error_to_info_array(caught)
      )
    ensure
      @messages.pop
    end

    # Add a line break if the last output was a #print instead of a #puts.
    def break_after_print
      checked_puts if @prev_printed
    end

    # Alias original #puts and #p methods.
    alias_method :real_puts, :puts
    alias_method :real_p, :p
    public :real_puts
    public :real_p

    private

    # Output data related to a failure.
    def puts_failure_data header:, additional_info: []
      break_after_print
      checked_puts header + @messages.join(SEPERATOR)

      additional_info.each.with_index do |text, index|
        checked_puts indent(text, index + 1)
      end
    end

    # Perform a #puts and then set a flag for future line breaks.
    def checked_puts object = ''
      real_puts object
      @prev_printed = false
    end

    # Perform a #print and then set a flag for future line breaks.
    def checked_print object = ''
      print object
      @prev_printed = true
    end

    # Indent each line of a given string by a given amount.
    def indent string, amount
      indent_string = ' ' * amount * INDENT_DEPTH
      string.gsub(/^/, indent_string)
    end

    # Convert an error object into an array of strings describing the error.
    def error_to_info_array error
      [
        "#{error.class}: #{error.message}",
        error.backtrace
             .reject { |path| path.match?(/^#{__FILE__}:/) }
             .join(?\n)
      ]
    end
  end
end

# Group together assertions and groups under a given name.
def group name
  TetCore.group(name) { yield }
end

# Assert that a given block will return true.
def assert name
  TetCore.group(name) do
    TetCore.assert

    yield ? TetCore.pass : TetCore.fail
  end
end

# Assert that a given block will raise an expected error.
def error name, expect:
  TetCore.group(name) do
    begin
      TetCore.assert
      yield
    rescue expect
      TetCore.pass
    else
      TetCore.fail
    end
  end
end

# A redefined version of #puts which ensures a line break before the printed
# object (for easier debugging).
def puts object = ''
  TetCore.break_after_print
  TetCore.real_puts(object)
end

# A redefined version of #p which ensures a line break before the printed
# object (for easier debugging).
def p object
  TetCore.break_after_print
  TetCore.real_p(object)
end
