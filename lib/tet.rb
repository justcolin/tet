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
    puts
    puts_report 'Failures',   failure_report
    puts_report 'Exceptions', error_report
    puts_report 'Statistics', statistics_report
  end



  # An exception class to distinguish errors from incorrectly written tests.
  class TestError < StandardError; end



  # Object oriented ways to do string formatting.
  module StringFormatting
    refine String do
      def indent
        gsub(/^/, '    ')
      end

      def to_label_string
        self
      end
    end

    refine Module do
      def to_label_string
        name
      end
    end

    refine Object do
      def to_label_string
        inspect
      end
    end
  end

  using StringFormatting



  # Helpers for building test methods.
  class << self
    # Call when an assertion has passed.
    def passed
      print_now ?.
      Data.add_note(:pass)
    end

    # Call when an assertion has failed.
    def failed
      print_now ?!
      Data.add_note(:fail)
    end

    # Call when an assertion has erred.
    def erred caught, expected = nil
      print_now ??
      Data.add_note(:error, caught: caught, expected: expected)
    end

    # Run a block as a test.
    def run label:,
            truthy:  -> { },
            falsy:   -> { },
            error:   ->(caught) { erred(caught) },
            no_nest: false,
            test:

      Data.with_label(label) do
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

    # Print out a string immediately. Calling #print alone may have a delay.
    def print_now string
      print string
      $stdout.flush
    end

    # Print out a report to stdout.
    def puts_report header, content
      unless content.empty?
        puts
        puts "#{header}:"
        puts content.indent
      end
    end

    # Render a string with details about all of the test run.
    def statistics_report
      pass_count  = Data.count_type(:pass)
      fail_count  = Data.count_type(:fail)
      error_count = Data.count_type(:error)

      output = []
      output << "Errors: #{error_count}" unless error_count.zero?
      output << "Failed: #{fail_count}"  unless fail_count.zero?
      output << "Passed: #{pass_count}"  unless pass_count.zero?

      output.join(?\n)
    end

    # Render a string with details about all of the failures encountered.
    def failure_report
      errors = Data.select_type(:error)

      Data.select_type(:fail, :error)
          .map do |node|
            node.label
                .tap do |label|
                  if node.type == :error
                    error_note  = "EXCEPTION_#{1 + errors.index(node)}"
                    expected    = node.data[:expected]
                    error_note << " (expected: #{expected}" if expected

                    label << error_note
                  end
                end
                .map(&:to_label_string)
                .join('  ::  ')
          end
          .join(?\n)
    end

    # Render a string with details about all of the errors encountered.
    def error_report
      Data.select_type(:error)
          .map.with_index do |node, index|
            error    = node.data[:caught]
            message  = error.to_s
            message << " (#{error.class})" if message != error.class.to_s
            summary  = "#{index + 1}. #{message}"

            error.backtrace
                 .reject { |line| line.start_with?(__FILE__) }
                 .map    { |line| line.indent }
                 .unshift(summary)
                 .join(?\n)
          end
          .join("\n\n")
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


  # Because tests are represented as series of nested groups containing
  # assertions, the test data is stored in a tree.
  module Tree
    module Basics
      include Enumerable

      # Create and append a new node to this node, returning the new node.
      def append_node type, data
        Node.new(type: type, data: data, parent: self)
            .tap { |node| @children << node }
      end

      # Recursively iterate over each node in the test data tree in the order
      # that they were added.
      def each &block
        @children.each do |node|
          block.call(node)
          node.each(&block)
        end
      end
    end

    # The root of the tree with methods to terminate Node methods which search
    # up the tree, as well as methods for enumerating over the test data, adding
    # labels and adding nodes.
    class Root
      include Basics

      def initialize
        @children     = []
        @current_node = self
      end

      # Terminate Node#label.
      def label
        []
      end

      # Run a block where any notes added will be inside a new label node.
      def with_label label
        previous      = @current_node
        @current_node = add_note(:label, label)
        yield
      ensure
        @current_node = previous
        self
      end

      # Add a node to note some data within the node that is currently active.
      def add_note type, data = nil
        @current_node.append_node(type, data)
      end

      # Get an array of all nodes of some type in the order they were added.
      def select_type *types
        select { |node| types.include?(node.type) }
      end

      # Count the number of nodes of a given type.
      def count_type type
        select_type(type).size
      end
    end

    # A node to store data about that some point in the test tree
    class Node
      include Basics
      attr_reader :data, :type

      def initialize parent:, type:, data: nil
        @type     = type
        @data     = data
        @parent   = parent
        @children = []
      end

      # Generate the array of labels that identify this point in the tree.
      def label
        if @type == :label
          @parent.label + [@data]
        else
          @parent.label
        end
      end
    end
  end

  # The instance of the Tree data structure that stores all of the test results.
  Data = Tree::Root.new
end
