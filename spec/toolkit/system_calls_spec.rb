require 'spec_helper'
require 'suse/toolkit/system_calls'

describe SUSE::Toolkit::SystemCalls do

  subject { Open3 }
  let(:date) { 'Fr 13. Jun 10:50:53 CEST 2014' }
  let(:success) { double('Process Status', :exitstatus => 0) }
  let(:failure) { double('Process Status', :exitstatus => 1) }
  let(:error_message) { 'Root privileges are required for installing or uninstalling packages' }
  include_context 'shared lets'

  include SUSE::Toolkit::SystemCalls

  before do
    subject.send(:include, SUSE::Toolkit::SystemCalls)
  end

  describe '.execute' do

    it 'should make a quiet system call' do
      subject.should_receive(:capture3).with(shared_env_hash, 'date').and_return([date, '', success])
      execute('date').should be nil
    end

    it 'should produce debug log output' do
      SUSE::Connect::GlobalLogger.instance.log.should_receive(:debug).with(/Executing:/)
      SUSE::Connect::GlobalLogger.instance.log.should_receive(:debug).with(/Output:/)
      subject.should_receive(:capture3).with(shared_env_hash, 'date').and_return([date, '', success])
      expect(execute('date', false)).to eql date
    end

    it 'should produce error log output' do
      SUSE::Connect::GlobalLogger.instance.log.should_receive(:error)

      subject.should_receive(:capture3).with(shared_env_hash, 'unknown').and_return(['', error_message, failure])
      expect { execute('unknown') }.to raise_error(SUSE::Connect::SystemCallError, error_message)
    end

    it 'should make a system call and return output from system' do
      subject.should_receive(:capture3).with(shared_env_hash, 'date').and_return([date, '', success])
      expect(execute('date', false)).to eql date
    end

    it 'should raise SystemCallError exception' do
      subject.should_receive(:capture3).with(shared_env_hash, 'unknown').and_return(['', error_message, failure])

      SUSE::Connect::GlobalLogger.instance.log.should_receive(:error)
      expect { execute('unknown') }.to raise_error(SUSE::Connect::SystemCallError, error_message)
    end

    it 'should raise ZypperError exception' do
      subject.should_receive(:capture3).with(shared_env_hash, 'zypper unknown').and_return(['', error_message, failure])

      SUSE::Connect::GlobalLogger.instance.log.should_receive(:error)
      expect { execute('zypper unknown') }.to raise_error(SUSE::Connect::ZypperError, error_message)
    end

    it 'should raise ZypperError with proper message if call returns bad exit status and error message is empty' do
      subject.should_receive(:capture3).with(shared_env_hash, 'zypper --xmlout products -i').and_return(['error message', '', failure])

      SUSE::Connect::GlobalLogger.instance.log.should_receive(:error)
      expect { execute('zypper --xmlout products -i') }.to raise_error(SUSE::Connect::ZypperError, 'error message')
    end

    it 'should raise in case zypper tries to go interactive' do
      subject.should_receive(:capture3).with(shared_env_hash, 'zypper --non-interactive refresh-services -r')
        .and_return(['test', 'ABORT request', success])
      expect { execute('zypper --non-interactive refresh-services -r') }.to raise_error(SUSE::Connect::ZypperError, /ABORT request/)
    end

  end

end
