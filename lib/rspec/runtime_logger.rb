require "rspec/runtime_logger/version"
require "rspec/core/formatters/base_formatter"

module RSpec
  module RuntimeLogger
    @max_record_count = 20

    def self.max_record_count
      @max_record_count
    end

    def self.max_record_count=(value)
      @max_record_count = value
    end

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

      def max_record_count
        RuntimeLogger.max_record_count
      end

      def start(*args)
        super
        @runtimes = {}
        @existing_runtimes = {}
        @existing_runtime_count = 0
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

          @runtimes[file_path] ||= 0
          @runtimes[file_path] += (runtime * 1_000).to_i # msec
        end
      end

      def start_dump
        File.open(@filename, 'wb') do |io|
          (@runtimes.keys | @existing_runtimes.keys).sort.each do |filename|
            runtime = @runtimes[filename]

            existing_runtimes = @existing_runtimes[filename] || Array.new(@existing_runtime_count, 'na')
            existing_runtimes = existing_runtimes.take(max_record_count - 1)
            next if runtime.nil? && existing_runtimes.all? {|rt| rt == 'na' }

            io.puts [filename, runtime || 'na', *existing_runtimes].join("\t")
          end
        end
      end

      private

      def load_existing_runtime_log
        return unless File.file? @filename

        File.read(@filename, mode: 'rb').each_line do |line|
          filename, *runtimes = line.strip.split(/\t/)
          @existing_runtimes[filename] = runtimes.map do |runtime|
            runtime == 'na' ? 'na' : runtime.to_i
          end
        end
        @existing_runtime_count = @existing_runtimes.each_value.first.size
      end
    end
  end
end
