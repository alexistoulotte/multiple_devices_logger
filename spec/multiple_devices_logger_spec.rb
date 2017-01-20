require 'spec_helper'

describe MultipleDevicesLogger do

  let(:logger) { MultipleDevicesLogger.new }

  it 'is a Logger' do
    expect(logger).to be_a(Logger)
  end

  describe '#add' do

    before :each do
      logger.add_device(STDERR, '>= WARN')
    end

    it 'write to device' do
      expect(STDERR).to receive(:write).with(/BAM!/)
      logger.add(Logger::WARN, 'BAM!')
    end

    it 'use a default formatter' do
      expect(STDERR).to receive(:write).with(/^W, \[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+ #\d+\]  WARN -- MyApp: BAM!\n$/)
      logger.add(Logger::WARN, 'BAM!', 'MyApp')
    end

    it 'write to multiple device if configured' do
      logger.add_device(STDOUT)
      expect(STDERR).to receive(:write).with(/BAM!/)
      expect(STDOUT).to receive(:write).with(/BAM!/)
      logger.add(Logger::WARN, 'BAM!')
    end

    it 'does not write anything if given severity is lower than configured level' do
      logger.level = :error
      expect(STDERR).not_to receive(:write)
      logger.add(Logger::WARN, 'BAM!')
    end

    it 'severity is UNKNOWN if not specified' do
      expect(STDERR).to receive(:write).with(/ANY -- : BIM!/)
      logger.add(nil, 'BIM!')
    end

    it 'a block can be given' do
      expect(STDERR).to receive(:write).with(/BIM!/)
      logger.add(Logger::ERROR) { 'BIM!' }
    end

    it 'accepts progname' do
      expect(STDERR).to receive(:write).with(/FATAL -- MyApp: BAM!/)
      logger.add(Logger::FATAL, 'BAM!', 'MyApp')
    end

    it 'returns true' do
      expect(STDERR).to receive(:write)
      expect(logger.add(Logger::WARN, 'BAM!')).to be(true)
    end

    it 'returns true if nothing is written' do
      logger.level = :error
      expect(STDERR).not_to receive(:write)
      expect(logger.add(Logger::WARN, 'BAM!')).to be(true)
    end

    it 'block is ignored if message is given' do
      expect(STDERR).to receive(:write).with(/BAM!/)
      logger.add(Logger::WARN, 'BAM!') { 'BIM!' }
    end

    it 'message is progname if nil' do
      expect(STDERR).to receive(:write).with(/WARN -- : BAM!/)
      logger.add(Logger::WARN, nil, 'BAM!')
    end

    it 'a formatter could be given' do
      logger.formatter = -> (severity, time, progname, message) { "Hello #{progname}: #{message}"  }
      expect(STDERR).to receive(:write).with('Hello World: cool')
      logger.add(Logger::WARN, 'cool', 'World')
    end

  end

  describe '#add_device' do

    it 'adds a device for all severities if given severity is nil' do
      expect {
        logger.add_device(STDOUT)
      }.to change { logger.devices_for(Logger::INFO).size }.by(1)
      expect(logger.devices_for(Logger::WARN).first.dev).to be(STDOUT)
    end

    it 'does not adds to other severities if severity is specified' do
      logger.add_device(STDERR, Logger::WARN)
      expect(logger.devices_for(Logger::WARN)).not_to be_empty
      expect(logger.devices_for(Logger::INFO)).to be_empty
      expect(logger.devices_for(Logger::ERROR)).to be_empty
    end

    it 'severity can be specified as constant' do
      expect {
        logger.add_device(STDERR, Logger::WARN)
      }.to change { logger.devices_for(Logger::WARN).first.try(:dev) }.from(nil).to(STDERR)
    end

    it 'severity can be specified as symbol' do
      expect {
        logger.add_device(STDOUT, :warn)
      }.to change { logger.devices_for(Logger::WARN).size }.by(1)
    end

    it 'severity can be specified as symbol (ignore case)' do
      expect {
        logger.add_device(STDOUT, :waRN)
      }.to change { logger.devices_for(Logger::WARN).size }.by(1)
    end

    it 'severity can be specified as string' do
      expect {
        logger.add_device(STDOUT, 'fatal')
      }.to change { logger.devices_for(Logger::FATAL).size }.by(1)
    end

    it 'severity can be specified as string (ignore case)' do
      expect {
        logger.add_device(STDOUT, 'FATal')
      }.to change { logger.devices_for(Logger::FATAL).size }.by(1)
    end

    it 'severity can be specified as string (with extra spaces)' do
      expect {
        logger.add_device(STDOUT, " fatal \n")
      }.to change { logger.devices_for(Logger::FATAL).size }.by(1)
    end

    it 'severity can be specified as integer' do
      expect {
        logger.add_device(STDOUT, 0)
      }.to change { logger.devices_for(Logger::DEBUG).size }.by(1)
    end

    it 'severity can be specified as integer (as string)' do
      expect {
        logger.add_device(STDOUT, '3')
      }.to change { logger.devices_for(Logger::ERROR).size }.by(1)
    end

    it 'severity can be specified as integer (as string with spaces)' do
      expect {
        logger.add_device(STDOUT, ' 2  ')
      }.to change { logger.devices_for(Logger::WARN).size }.by(1)
    end

    it 'many severities can be given' do
      logger.add_device(STDERR, Logger::DEBUG, Logger::WARN)
      expect(logger.devices_for(Logger::DEBUG)).not_to be_empty
      expect(logger.devices_for(Logger::WARN)).not_to be_empty
      expect(logger.devices_for(Logger::INFO)).to be_empty
      expect(logger.devices_for(Logger::ERROR)).to be_empty
    end

    it 'an array of severities can be given' do
      logger.add_device(STDERR, [Logger::DEBUG, Logger::WARN])
      expect(logger.devices_for(Logger::DEBUG)).not_to be_empty
      expect(logger.devices_for(Logger::WARN)).not_to be_empty
      expect(logger.devices_for(Logger::INFO)).to be_empty
    end

    it 'avoids doubloons on severities' do
      logger.add_device(STDOUT, Logger::DEBUG, Logger::INFO, Logger::DEBUG)
      expect(logger.devices_for(Logger::DEBUG).size).to eq(1)
    end

    it 'raise an error if severity specified as integer is too high' do
      expect {
        logger.add_device(STDERR, 8)
      }.to raise_error(ArgumentError, 'Invalid log severity: 8')
    end

    it 'raise an error if severity specified as integer is negative' do
      expect {
        logger.add_device(STDERR, -1)
      }.to raise_error(ArgumentError, 'Invalid log severity: -1')
    end

    it 'does not add any device if one severity is invalid' do
      expect {
        expect {
          logger.add_device(STDOUT, Logger::DEBUG, 'bim')
        }.to raise_error(ArgumentError, 'Invalid log severity: "bim"')
      }.not_to change { logger.devices_for(Logger::DEBUG).size }
    end

    it 'raise an error if severity is unknown (as string)' do
      expect {
        logger.add_device(STDOUT, 'errors')
      }.to raise_error(ArgumentError, 'Invalid log severity: "errors"')
    end

    it 'may have many device for a severity' do
      logger.add_device(STDERR, Logger::INFO).add_device(STDOUT, Logger::INFO)
      expect(logger.devices_for(Logger::DEBUG)).to be_empty
      expect(logger.devices_for(Logger::INFO).size).to eq(2)
      expect(logger.devices_for(Logger::FATAL)).to be_empty
    end

    it 'returns self' do
      expect(logger.add_device(STDOUT)).to be(logger)
      expect(logger.add_device(STDOUT, Logger::DEBUG)).to be(logger)
    end

    it 'accepts <= operator' do
      logger.add_device(STDOUT, '<= warn')
      expect(logger.devices_for(Logger::DEBUG)).not_to be_empty
      expect(logger.devices_for(Logger::INFO)).not_to be_empty
      expect(logger.devices_for(Logger::WARN)).not_to be_empty
      expect(logger.devices_for(Logger::ERROR)).to be_empty
    end

    it 'accepts < operator' do
      logger.add_device(STDOUT, '< warn')
      expect(logger.devices_for(Logger::DEBUG)).not_to be_empty
      expect(logger.devices_for(Logger::INFO)).not_to be_empty
      expect(logger.devices_for(Logger::WARN)).to be_empty
      expect(logger.devices_for(Logger::ERROR)).to be_empty
    end

    it 'accepts > operator' do
      logger.add_device(STDOUT, '> error')
      expect(logger.devices_for(Logger::UNKNOWN)).not_to be_empty
      expect(logger.devices_for(Logger::FATAL)).not_to be_empty
      expect(logger.devices_for(Logger::ERROR)).to be_empty
    end

    it 'accepts >= operator' do
      logger.add_device(STDOUT, '>= error')
      expect(logger.devices_for(Logger::UNKNOWN)).not_to be_empty
      expect(logger.devices_for(Logger::FATAL)).not_to be_empty
      expect(logger.devices_for(Logger::ERROR)).not_to be_empty
      expect(logger.devices_for(Logger::WARN)).to be_empty
    end

    it 'accepts operator with spaces and with a different case' do
      logger.add_device(STDOUT, " \n > eRRor  ")
      expect(logger.devices_for(Logger::UNKNOWN)).not_to be_empty
      expect(logger.devices_for(Logger::FATAL)).not_to be_empty
      expect(logger.devices_for(Logger::ERROR)).to be_empty
    end

    it 'accepts operator with no spaces' do
      logger.add_device(STDOUT, ">error")
      expect(logger.devices_for(Logger::UNKNOWN)).not_to be_empty
      expect(logger.devices_for(Logger::FATAL)).not_to be_empty
      expect(logger.devices_for(Logger::ERROR)).to be_empty
    end

    it 'raise an error if operator is invalid' do
      expect {
        logger.add_device(STDERR, '!> error')
      }.to raise_error(ArgumentError, 'Invalid log severity: "!> error"')
    end

    it 'raise an error if severity is invalid (with operator)' do
      expect {
        logger.add_device(STDERR, '>= foo')
      }.to raise_error(ArgumentError, 'Invalid log severity: "foo"')
    end

    it 'avoid doubloons with operator' do
      logger.add_device(STDERR, Logger::INFO, '>= DEBUG')
      expect(logger.devices_for(Logger::DEBUG).size).to eq(1)
      expect(logger.devices_for(Logger::INFO).size).to eq(1)
      expect(logger.devices_for(Logger::WARN).size).to eq(1)
    end

    it 'may have many devices for a severity with an operator' do
      logger.add_device(STDERR, Logger::INFO).add_device(STDOUT, '<= error')
      expect(logger.devices_for(Logger::DEBUG).size).to eq(1)
      expect(logger.devices_for(Logger::INFO).size).to eq(2)
      expect(logger.devices_for(Logger::FATAL)).to be_empty
    end

    it 'register LogDevice directly if a LogDevice is given' do
      device = Logger::LogDevice.new(STDERR)
      logger.add_device(device, Logger::INFO)
      expect(logger.devices_for(Logger::INFO).first).to be(device)
    end

    it 'given options are forwared to LogDevice constructor' do
      expect(Logger::LogDevice).to receive(:new).with(STDOUT, foo: 'bar')
      logger.add_device(STDOUT, Logger::INFO, foo: 'bar')
    end

    it 'raise an error for default severity' do
      expect {
        logger.add_device(STDERR, 'default')
      }.to raise_error(ArgumentError, 'Invalid log severity: "default"')
    end

  end

  describe '#clear_devices' do

    it 'removes registered loggers' do
      logger.add_device(STDERR)
      expect {
        logger.clear_devices
      }.to change { logger.devices_for(Logger::DEBUG) }.to([])
    end

  end

  describe '#default_device' do

    it 'is nil by default' do
      expect(logger.default_device).to be_nil
    end

    it 'can be changed' do
      logger.default_device = STDERR
      expect(logger.default_device).not_to be_nil
    end

    it 'is converted to a LogDevice when set' do
      logger.default_device = STDERR
      expect(logger.default_device).to be_a(Logger::LogDevice)
      expect(logger.default_device.dev).to be(STDERR)
    end

    it 'is not converted to a LogDevice when a LogDevice is set' do
      device = Logger::LogDevice.new(STDOUT)
      logger.default_device = device
      expect(logger.default_device).to be(device)
      expect(logger.default_device.dev).to be(STDOUT)
    end

  end

  describe '#devices_for' do

    it 'accepts strings' do
      logger.add_device(STDERR, 'warn')
      expect(logger.devices_for('warn').size).to eq(1)
    end

    it 'returns a LogDevice instance' do
      logger.add_device(STDERR, 'warn')
      expect(logger.devices_for(:warn).first).to be_a(Logger::LogDevice)
      expect(logger.devices_for(:warn).first.dev).to be(STDERR)
    end

    it 'returns an empty array if there is not registered device for given severity' do
      expect(logger.devices_for(Logger::WARN)).to eq([])
    end

    it 'returns default device if there is no device for given severity' do
      logger.default_device = STDERR
      logger.add_device(STDOUT, '>= warn')
      expect(logger.devices_for(:debug).first.dev).to be(STDERR)
      expect(logger.devices_for(:warn).first.dev).to be(STDOUT)
      expect(logger.devices_for(:error).first.dev).to be(STDOUT)
    end

    it 'default is never used if a logger has been added to all severity' do
      logger.default_device = STDERR
      logger.add_device(STDOUT)
      expect(logger.devices_for(:debug).first.dev).to be(STDOUT)
      expect(logger.devices_for(:warn).first.dev).to be(STDOUT)
      expect(logger.devices_for(:error).first.dev).to be(STDOUT)
    end

  end

  describe '#initialize' do

    it 'accepts no argument' do
      expect {
        MultipleDevicesLogger.new
      }.not_to raise_error
    end

    it 'logdev is nil' do
      expect(logger.instance_variable_get(:@logdev)).to be_nil
    end

  end

  describe '#level' do

    it 'is debug by default' do
      expect(logger.level).to eq(Logger::DEBUG)
    end

    it 'is not changed when adding devices' do
      expect {
        logger.add_device(STDOUT, '> WARN')
      }.not_to change { logger.level }
    end

  end

  describe '#log' do

    it 'works like expected' do
      logger.add_device(STDOUT, Logger::WARN)
      expect(STDOUT).to receive(:write).with(/WARN -- : BAM!/)
      logger.log(Logger::WARN, 'BAM!')
    end

  end

  describe '#reopen' do

    it 'raise an NotImplementedError' do
      expect {
        logger.reopen
      }.to raise_error(NotImplementedError, 'MultipleDevicesLogger#reopen')
    end

  end

  describe '#warn' do

    it 'does not output anything if there is no device' do
      logger.add_device(STDOUT, Logger::DEBUG)
      expect(STDOUT).not_to receive(:write)
      logger.warn('BAM!')
    end

    it 'output message to device if configured' do
      logger.add_device(STDOUT, Logger::WARN)
      expect(STDOUT).to receive(:write).with(/WARN -- : BAM!/)
      logger.warn('BAM!')
    end

  end

  describe '@logdev' do

    let(:logdev) { logger.instance_variable_get(:@logdev) }

    it 'is nil' do
      expect(logdev).to be_nil
    end

  end

end
