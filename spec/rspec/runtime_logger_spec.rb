require 'spec_helper'
require 'rspec/runtime_logger'

require 'pathname'
require 'tmpdir'
require 'timecop'

describe RSpec::RuntimeLogger::Formatter do
  let(:output) { StringIO.new }
  subject(:formatter) { described_class.new(output) }

  around do |current_example|
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        current_example.run
      end
    end
  end

  context 'when SPEC_RUNTIME_LOG environment variable is not given' do
    before do
      ENV.delete 'SPEC_RUNTIME_LOG'
      formatter.start(2)
    end

    it 'does not produce anything to the output' do
      formatter.start_dump
      expect(output.string).to eq('')
    end

    it 'creates "spec_runtime_log.tsv" in the current directory' do
      formatter.start_dump
      expect(Pathname("spec_runtime_log.tsv")).to be_file
    end

    it 'records runtimes in tsv format' do
      Timecop.freeze(Time.local(2000, 1, 1, 12, 00, 00)) do
        formatter.example_group_started(double(:example_group_a, file_path: 'a_spec.rb', top_level?: true))
      end
      Timecop.freeze(Time.local(2000, 1, 1, 12, 01, 00)) do
        formatter.example_group_finished(double(:example_group_a, file_path: 'a_spec.rb', top_level?: true))
      end

      Timecop.freeze(Time.local(2000, 1, 1, 12, 00, 00)) do
        formatter.example_group_started(double(:example_group_a, file_path: 'b_spec.rb', top_level?: true))
      end
      Timecop.freeze(Time.local(2000, 1, 1, 12, 00, 40)) do
        formatter.example_group_finished(double(:example_group_a, file_path: 'b_spec.rb', top_level?: true))
      end

      formatter.start_dump
      log = File.read("spec_runtime_log.tsv")
      expect(log).to eq("a_spec.rb\t60000\nb_spec.rb\t40000\n")
    end

    context 'when two toplevel example groups are in a spec file' do
      it 'adds runtimes of these example groups' do
        Timecop.freeze(Time.local(2000, 1, 1, 12, 00, 00)) do
          formatter.example_group_started(double(:example_group_a, file_path: 'a_spec.rb', top_level?: true))
        end
        Timecop.freeze(Time.local(2000, 1, 1, 12, 01, 00)) do
          formatter.example_group_finished(double(:example_group_a, file_path: 'a_spec.rb', top_level?: true))
        end

        Timecop.freeze(Time.local(2000, 1, 1, 12, 00, 00)) do
          formatter.example_group_started(double(:example_group_a, file_path: 'a_spec.rb', top_level?: true))
        end
        Timecop.freeze(Time.local(2000, 1, 1, 12, 00, 40)) do
          formatter.example_group_finished(double(:example_group_a, file_path: 'a_spec.rb', top_level?: true))
        end

        formatter.start_dump
        log = File.read("spec_runtime_log.tsv")
        expect(log).to eq("a_spec.rb\t100000\n")
      end
    end

    context 'when old runtime log is exist' do
      before do
        File.write('spec_runtime_log.tsv', "a_spec.rb\t30000\n")
        formatter.start(2)
      end

      it 'appends runtimes in tsv format' do
        Timecop.freeze(Time.local(2000, 1, 1, 12, 00, 00)) do
          formatter.example_group_started(double(:example_group_a, file_path: 'a_spec.rb', top_level?: true))
        end
        Timecop.freeze(Time.local(2000, 1, 1, 12, 01, 00)) do
          formatter.example_group_finished(double(:example_group_a, file_path: 'a_spec.rb', top_level?: true))
        end

        Timecop.freeze(Time.local(2000, 1, 1, 12, 00, 00)) do
          formatter.example_group_started(double(:example_group_a, file_path: 'b_spec.rb', top_level?: true))
        end
        Timecop.freeze(Time.local(2000, 1, 1, 12, 00, 40)) do
          formatter.example_group_finished(double(:example_group_a, file_path: 'b_spec.rb', top_level?: true))
        end

        formatter.start_dump
        log = File.read("spec_runtime_log.tsv")
        expect(log).to eq("a_spec.rb\t60000\t30000\nb_spec.rb\t40000\tna\n")
      end
    end

    context 'when RSpec::RuntimeLogger.max_record_count is 2' do
      before do
        RSpec::RuntimeLogger.max_record_count = 2
      end

      it 'removes the 3rd and the subsequent runtime entries' do
        File.write('spec_runtime_log.tsv', "a_spec.rb\t30000\t40000\n")
        formatter.start(2)

        Timecop.freeze(Time.local(2000, 1, 1, 12, 00, 00)) do
          formatter.example_group_started(double(:example_group_a, file_path: 'a_spec.rb', top_level?: true))
        end
        Timecop.freeze(Time.local(2000, 1, 1, 12, 01, 00)) do
          formatter.example_group_finished(double(:example_group_a, file_path: 'a_spec.rb', top_level?: true))
        end

        Timecop.freeze(Time.local(2000, 1, 1, 12, 00, 00)) do
          formatter.example_group_started(double(:example_group_a, file_path: 'b_spec.rb', top_level?: true))
        end
        Timecop.freeze(Time.local(2000, 1, 1, 12, 00, 40)) do
          formatter.example_group_finished(double(:example_group_a, file_path: 'b_spec.rb', top_level?: true))
        end

        formatter.start_dump
        log = File.read("spec_runtime_log.tsv")
        expect(log).to eq("a_spec.rb\t60000\t30000\nb_spec.rb\t40000\tna\n")
      end

      it 'recores "na" for removed spec files' do
        File.write('spec_runtime_log.tsv', "a_spec.rb\t30000\t40000\n")
        formatter.start(2)

        Timecop.freeze(Time.local(2000, 1, 1, 12, 00, 00)) do
          formatter.example_group_started(double(:example_group_a, file_path: 'b_spec.rb', top_level?: true))
        end
        Timecop.freeze(Time.local(2000, 1, 1, 12, 01, 00)) do
          formatter.example_group_finished(double(:example_group_a, file_path: 'b_spec.rb', top_level?: true))
        end

        formatter.start_dump
        log = File.read("spec_runtime_log.tsv")
        expect(log).to eq("a_spec.rb\tna\t30000\nb_spec.rb\t60000\tna\n")
      end

      it 'removes the entries of spec file whose all the runtimes are "na"' do
        File.write('spec_runtime_log.tsv', "a_spec.rb\t30000\t40000\nc_spec.rb\tna\t60000\n")
        formatter.start(2)

        Timecop.freeze(Time.local(2000, 1, 1, 12, 00, 00)) do
          formatter.example_group_started(double(:example_group_a, file_path: 'a_spec.rb', top_level?: true))
        end
        Timecop.freeze(Time.local(2000, 1, 1, 12, 01, 00)) do
          formatter.example_group_finished(double(:example_group_a, file_path: 'a_spec.rb', top_level?: true))
        end

        formatter.start_dump
        log = File.read("spec_runtime_log.tsv")
        expect(log).to eq("a_spec.rb\t60000\t30000\n")
      end
    end
  end

  context 'when SPEC_RUNTIME_LOG environment variable is given' do
    before do
      ENV['SPEC_RUNTIME_LOG'] = 'specified_log_file.tsv'
      formatter.start(2)
    end

    it 'creates "spec_runtime_log.tsv" in the current directory' do
      formatter.start_dump
      expect(Pathname('specified_log_file.tsv')).to be_file
    end
  end
end
