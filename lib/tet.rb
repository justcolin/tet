# Copyright (C) 2017 Colin Fulton
# All rights reserved.
#
# This software may be modified and distributed under the
# terms of the three-clause BSD license. See LICENSE.txt
# (located in root directory of this project) for details.

module TetCore
  INDENT_DEPTH = 4
  SEPERATOR    = '  :  '
  FAIL_HEADER  = 'FAIL  :  '
  ERROR_HEADER = 'ERROR :  '

  @previous_passed = false
  @messages        = []
  @counts          = Struct.new(:tests, :fails, :errors)
                          .new(0,      0,      0)

  class << self
    def assert
      @counts.tests += 1
    end

    def pass
      print ?.
      @previous_passed = true
    end

    def fail
      @counts.fails += 1
      puts_failure_data(header: FAIL_HEADER)
    end

    def group name
      @messages << name
      yield
    rescue Exception => caught
      @counts.errors += 1
      puts_failure_data(
        header:          ERROR_HEADER,
        additional_info: error_to_info_array(caught)
      )
    ensure
      @messages.pop
    end

    def puts_failure_data header:, additional_info: []
      puts if @previous_passed
      puts header + @messages.join(SEPERATOR)

      additional_info.each.with_index do |text, index|
        puts indent(text, index + 1)
      end

      @previous_passed = false
    end

    private

    def indent string, amount
      indent_string = ' ' * amount * INDENT_DEPTH
      string.gsub(/^/, indent_string)
    end

    def error_to_info_array error
      [
        "#{error.class}: #{error.message}",
        error.backtrace
             .reject { |path| path.match?(/^#{__FILE__}:/) }
             .join(?\n)
      ]
    end
  end

  at_exit {
    puts "\nTests: #{@counts.tests}   Fails: #{@counts.fails}   Errors: #{@counts.errors}"
  }
end

def group name, &block
  TetCore.group(name, &block)
end

def assert name
  TetCore.group(name) do
    TetCore.assert

    yield ? TetCore.pass : TetCore.fail
  end
end


def error name, expect: StandardError
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
