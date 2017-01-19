require 'spec_helper'

describe MultipleDevicesLogger do

  let(:logger) { MultipleDevicesLogger.new }

  it 'is a Logger' do
    expect(logger).to be_a(Logger)
  end

  describe '#add' do

    it 'should have specs'

  end

  describe '#add_device' do

    it 'adds a device for all levels if not level are given' do
      expect {
        logger.add_device(STDOUT)
      }.to change { logger.devices_for(Logger::INFO).size }.by(1)
      expect(logger.devices_for(Logger::WARN).first.dev).to be(STDOUT)
    end

    it 'does not adds to other levels if level is specified' do
      logger.add_device(STDERR, Logger::WARN)
      expect(logger.devices_for(Logger::WARN)).not_to be_empty
      expect(logger.devices_for(Logger::INFO)).to be_empty
      expect(logger.devices_for(Logger::ERROR)).to be_empty
    end

    it 'level can be specified as constant' do
      expect {
        logger.add_device(STDERR, Logger::WARN)
      }.to change { logger.devices_for(Logger::WARN).first.try(:dev) }.from(nil).to(STDERR)
    end

    it 'level can be specified as symbol' do
      expect {
        logger.add_device(STDOUT, :warn)
      }.to change { logger.devices_for(Logger::WARN).size }.by(1)
    end

    it 'level can be specified as symbol (ignore case)' do
      expect {
        logger.add_device(STDOUT, :waRN)
      }.to change { logger.devices_for(Logger::WARN).size }.by(1)
    end

    it 'level can be specified as string' do
      expect {
        logger.add_device(STDOUT, 'fatal')
      }.to change { logger.devices_for(Logger::FATAL).size }.by(1)
    end

    it 'level can be specified as string (ignore case)' do
      expect {
        logger.add_device(STDOUT, 'FATal')
      }.to change { logger.devices_for(Logger::FATAL).size }.by(1)
    end

    it 'level can be specified as string (with extra spaces)' do
      expect {
        logger.add_device(STDOUT, " fatal \n")
      }.to change { logger.devices_for(Logger::FATAL).size }.by(1)
    end

    it 'level can be specified as integer' do
      expect {
        logger.add_device(STDOUT, 0)
      }.to change { logger.devices_for(Logger::DEBUG).size }.by(1)
    end

    it 'level can be specified as integer (as string)' do
      expect {
        logger.add_device(STDOUT, '3')
      }.to change { logger.devices_for(Logger::ERROR).size }.by(1)
    end

    it 'level can be specified as integer (as string with spaces)' do
      expect {
        logger.add_device(STDOUT, ' 2  ')
      }.to change { logger.devices_for(Logger::WARN).size }.by(1)
    end

    it 'many levels can be given' do
      logger.add_device(STDERR, Logger::DEBUG, Logger::WARN)
      expect(logger.devices_for(Logger::DEBUG)).not_to be_empty
      expect(logger.devices_for(Logger::WARN)).not_to be_empty
      expect(logger.devices_for(Logger::INFO)).to be_empty
      expect(logger.devices_for(Logger::ERROR)).to be_empty
    end

    it 'an array of levels can be given' do
      logger.add_device(STDERR, [Logger::DEBUG, Logger::WARN])
      expect(logger.devices_for(Logger::DEBUG)).not_to be_empty
      expect(logger.devices_for(Logger::WARN)).not_to be_empty
      expect(logger.devices_for(Logger::INFO)).to be_empty
    end

    it 'avoids doubloons on levels' do
      logger.add_device(STDOUT, Logger::DEBUG, Logger::INFO, Logger::DEBUG)
      expect(logger.devices_for(Logger::DEBUG).size).to eq(1)
    end

    it 'raise an error if level specified as integer is too high' do
      expect {
        logger.add_device(STDERR, 8)
      }.to raise_error(ArgumentError, 'Invalid log level: 8')
    end

    it 'raise an error if level specified as integer is negative' do
      expect {
        logger.add_device(STDERR, -1)
      }.to raise_error(ArgumentError, 'Invalid log level: -1')
    end

    it 'does not add any device if one level is invalid' do
      expect {
        expect {
          logger.add_device(STDOUT, Logger::DEBUG, 'bim')
        }.to raise_error(ArgumentError, 'Invalid log level: "bim"')
      }.not_to change { logger.devices_for(Logger::DEBUG).size }
    end

    it 'raise an error if level is unknown (as string)' do
      expect {
        logger.add_device(STDOUT, 'errors')
      }.to raise_error(ArgumentError, 'Invalid log level: "errors"')
    end

    it 'may have many device for a level' do
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
      }.to raise_error(ArgumentError, 'Invalid log level: "!> error"')
    end

    it 'raise an error if level is invalid (with operator)' do
      expect {
        logger.add_device(STDERR, '>= foo')
      }.to raise_error(ArgumentError, 'Invalid log level: "foo"')
    end

    it 'avoid doubloons with operator' do
      logger.add_device(STDERR, Logger::INFO, '>= DEBUG')
      expect(logger.devices_for(Logger::DEBUG).size).to eq(1)
      expect(logger.devices_for(Logger::INFO).size).to eq(1)
      expect(logger.devices_for(Logger::WARN).size).to eq(1)
    end

    it 'may have many device for a level with an operator' do
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

    it 'accepts default level' do
      expect {
        logger.add_device(STDERR, 'default')
      }.not_to raise_error
    end

    it 'accepts default level (as symbol)' do
      expect {
        logger.add_device(STDERR, :default)
      }.not_to raise_error
    end

    it 'accepts default level (with spaces, ignore case)' do
      expect {
        logger.add_device(STDERR, "   DefaULt\n")
      }.not_to raise_error
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

    it 'returns an empty array if there is not registered device for given level' do
      expect(logger.devices_for(Logger::WARN)).to eq([])
    end

    it 'returns default device if there is no device for given level' do
      logger.add_device(STDERR, :default).add_device(STDOUT, '>= warn')
      expect(logger.devices_for(:debug).first.dev).to eq(STDERR)
      expect(logger.devices_for(:warn).first.dev).to eq(STDOUT)
      expect(logger.devices_for(:error).first.dev).to eq(STDOUT)
    end

    it 'default is never used if a logger has been added to all levels' do
      logger.add_device(STDERR, :default).add_device(STDOUT)
      expect(logger.devices_for(:debug).first.dev).to eq(STDOUT)
      expect(logger.devices_for(:warn).first.dev).to eq(STDOUT)
      expect(logger.devices_for(:error).first.dev).to eq(STDOUT)
    end

    it 'accepts default and other options' do
      logger.add_device(STDOUT, :default, Logger::WARN)
      expect(logger.devices_for(:debug).first.dev).to eq(STDOUT)
      expect(logger.devices_for(:warn).first.dev).to eq(STDOUT)
      expect(logger.devices_for(:error).first.dev).to eq(STDOUT)
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

  describe '#reopen' do

    it 'raise an NotImplementedError' do
      expect {
        logger.reopen
      }.to raise_error(NotImplementedError, 'MultipleDevicesLogger#reopen')
    end

  end

  describe '@logdev' do

    let(:logdev) { logger.instance_variable_get(:@logdev) }

    it 'is nil' do
      expect(logdev).to be_nil
    end

  end

  it 'should have more specs'

end
