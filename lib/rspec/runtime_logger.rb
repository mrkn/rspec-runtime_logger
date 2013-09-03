require "rspec/runtime_logger/version"
require "rspec/core/formatters/base_formatter"

module RSpec
  module RuntimeLogger
    class Formatter < RSpec::Core::Formatters::BaseFormatter
      DEFAULT_FILENAME = 'spec_runtime_log.tsv'.freeze

      def initialize(output)
        if String === output
          @filename = output
          output = StringIO.new
        else
          @filename = DEFAULT_FILENAME
        end
        super
      end

      def start(*args)
        super
        @runtimes = {}
        @runtime_count = 0
        load_existing_runtime_log
      end

      def example_group_started(example_group)
        super
        if example_group.top_level?
          @toplevel_example_group_started_at = Time.now
        end
      end

      def example_group_finished(example_group)
        super
        if example_group.top_level? && @toplevel_example_group_started_at
          file_path = example_group.file_path
          runtime = Time.now - @toplevel_example_group_started_at
          @toplevel_example_group_started_at = nil

          @runtimes[file_path] = Array.new(@runtime_count, 'na') unless @runtimes[file_path]
          @runtimes[file_path].unshift (runtime * 1_000).to_i  # msec
        end
      end

      def start_dump
        File.open(@filename, 'wb') do |io|
          @runtimes.keys.sort.each do |filename|
            io.puts [filename, *@runtimes[filename]].join("\t")
          end
        end
      end

      private

      def load_existing_runtime_log
        return unless File.file? @filename

        File.read(@filename, mode: 'rb').each_line do |line|
          filename, *runtimes = line.strip.split(/\t/)
          @runtimes[filename] = runtimes.map(&:to_i)
        end
        @runtime_count = @runtimes.each_value.first.size
      end
    end
  end
end
