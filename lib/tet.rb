# Copyright (C) 2017 Colin Fulton
# All rights reserved.
#
# This software may be modified and distributed under the
# terms of the three-clause BSD license. See LICENSE.txt
# (located in root directory of this project) for details.

# Label a block of tests.
def group label, &block
  Tet.run(
    label: label,
    test:  block
  )
end

# Assert that a block will return a truthy value.
def assert label = '', &block
  Tet.run(
    label:   label,
    test:    block,
    no_nest: true,
    truthy:  -> { Tet.passed },
    falsy:   -> { Tet.failed }
  )
end

# Assert that a block will err.
def err label = '', expect: StandardError, &block
  Tet.run(
    label:   label,
    test:    block,
    no_nest: true,
    truthy:  -> { Tet.failed },
    falsy:   -> { Tet.failed },
    error:   ->(caught) do
               (expect >= caught.class) ? Tet.passed : Tet.erred(caught, expect)
             end
  )
end



# A namespace for all of the helper methods and classes.
module Tet
  # Print all the reports after all the tests have run.
  at_exit do
    unless Stats.empty?
      puts
      puts_report 'Failures',   Messages.failure_report
      puts_report 'Exceptions', Messages.error_report
      puts_report 'Statistics', Stats.report
    end
  end



  # An exception class to distinguish errors from incorrectly written tests.
  class TestError < StandardError; end



  # Object oriented ways to do string formatting.
  module StringFormatting
    refine String do
      def indent
        gsub(/^/, '    ')
      end

      def to_label
        self
      end
    end

    refine Module do
      def to_label
        name
      end
    end

    refine Object do
      def to_label
        inspect
      end
    end
  end

  using StringFormatting



  # Helpers for building test methods.
  class << self
    # Call when an assertion has passed.
    def passed
      Stats.passed
    end

    # Call when an assertion has failed.
    def failed
      Stats.failed
      Messages.failed
    end

    # Call when an assertion has erred.
    def erred caught, expected = nil
      Stats.erred
      Messages.erred(caught, expected)
    end

    # Run a block as a test.
    def run label:,
            truthy:  -> { },
            falsy:   -> { },
            error:   ->(caught) { erred(caught) },
            no_nest: false,
            test:

      Messages.with_label(label) do
        nesting_guard(no_nest) do
          begin
            test.call ? truthy.call : falsy.call
          rescue TestError => caught
            erred(caught)
          rescue StandardError => caught
            error.call(caught)
          end
        end
      end

      nil
    end

    private

    # Print out a report to stdout.
    def puts_report header, content
      unless content.empty?
        puts
        puts "#{header}:"
        puts content.indent
      end
    end

    # Check and set a flag to prevent test blocks from nesting
    def nesting_guard guard_state
      raise TestError, 'assertions can not be nested' if @nesting_banned
      @nesting_banned = guard_state
      yield
    ensure
      @nesting_banned = false
    end
  end



  # Tracks and reports statistics about the tests that have run
  module Stats
    Counts = { passed: 0,  failed: 0,  erred: 0  }
    Marks  = { passed: ?., failed: ?!, erred: ?? }

    class << self
      # Call when an assertion has passed
      def passed
        log :passed
      end

      # Call when an assertion has failed
      def failed
        log :failed
      end

      # Call when an assertion has erred
      def erred
        log :erred
      end

      # Returns true if no statistics have been logged
      def empty?
        Counts.values.inject(&:+).zero?
      end

      # Returns a string with statistics about the tests that have been run
      def report
        errors = Counts[:erred]
        fails  = Counts[:failed]
        passes = Counts[:passed]

        output = []
        output << "Errors: #{errors}" unless errors.zero?
        output << "Failed: #{fails}"
        output << "Passed: #{passes}"

        output.join(?\n)
      end

      private

      # Log an event and print a mark to show progress is being made on tests
      def log type
        Counts[type] += 1

        print Marks[type]
        $stdout.flush
      end
    end
  end


  # Tracks and reports messages for each test
  module Messages
    Labels  = []
    Results = []
    Errors  = []

    class << self
      # Add a label to all subsequent messages
      def with_label label
        Labels.push(label)
        yield
      ensure
        Labels.pop
      end

      # Call when an assertion has failed
      def failed
        add_result!
      end

      # Call when an assertion has passed
      def erred caught, expected = nil
        number = Stats::Counts[:erred]
        label  = "EXCEPTION_#{number}"
        label << " (expected: #{expected})" if expected

        with_label(label) { add_result! }

        Errors.push(error_message(caught, number))
      end

      # Returns a string with details about all failed tests
      def failure_report
        Results.join(?\n)
      end

      # Returns a string with details about all errors
      def error_report
        Errors.join("\n\n")
      end

      private

      # Add a message for a new result using the current labels
      def add_result!
        Results.push(
          Labels.map { |raw| raw.to_label }
                .reject(&:empty?)
                .join('  ::  ')
        )
      end

      def format_label label
        case label
        when Module
          label.name
        when String
          label.to_s
        else
          label.inspect
        end
      end

      # Format an error into a message string
      def error_message error, number
        error_message  = error.to_s
        error_class    = error.class.to_s
        error_message << " (#{error.class})" if error_message != error_class

        summary  = "#{number}. #{error_message}"
        details  = error.backtrace
                        .reject { |line| line.start_with?(__FILE__) }
                        .map    { |line| line.indent }

        details.unshift(summary).join(?\n)
      end
    end
  end
end
