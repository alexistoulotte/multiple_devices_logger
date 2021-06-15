require 'active_support/core_ext/module'
require 'active_support/core_ext/string'
require 'logger'

class MultipleDevicesLogger < Logger

  SEVERITIES = {
    'debug' => DEBUG,
    'info' => INFO,
    'warn' => WARN,
    'error' => ERROR,
    'fatal' => FATAL,
    'unknown' => UNKNOWN,
  }.freeze

  attr_reader :default_device

  def initialize
    super(nil)
    clear_devices
  end

  def add(severity, message = nil, progname = nil)
    severity ||= UNKNOWN
    return true if severity < level
    progname ||= self.progname
    if message.nil?
      if block_given?
        message = yield
      else
        message = progname
        progname = self.progname
      end
    end
    return false if exception_ignored?(message)
    devices_for(severity).each do |device|
      next if device.exception_ignored?(message)
      formatter = device.formatter || self.formatter || @default_formatter
      device.write(formatter.call(format_severity(severity), Time.now, progname, message))
    end
    true
  end
  alias_method :log, :add

  def add_device(device, *severities)
    severities = [severities].flatten
    options = severities.last.is_a?(Hash) ? severities.pop : {}
    formatter = nil
    if options.key?(:formatter)
      formatter = options.delete(:formatter)
      raise ArgumentError.new("Formatter must respond to #call, #{formatter.inspect} given") unless formatter.respond_to?(:call)
    end
    ignored_exceptions = options.delete(:ignore_exceptions)
    device = LogDevice.new(device, **options) unless device.is_a?(Logger::LogDevice)
    device.formatter = formatter
    device.ignore_exceptions(ignored_exceptions) if ignored_exceptions.present?
    if severities.empty?
      keys = SEVERITIES.values
    else
      keys = severities.map { |severity| parse_severities_with_operator(severity) }.flatten.uniq
    end
    keys.each do |key|
      @devices[key] ||= []
      @devices[key] << device
    end
    self
  end

  def clear_devices
    @devices = {}
  end

  def default_device=(value)
    @default_device = value.is_a?(LogDevice) ? value : LogDevice.new(value)
  end

  def devices_for(severity)
    @devices[parse_severity(severity)] || [default_device].compact || []
  end

  def level=(value)
    super(parse_severity(value))
  end

  def reopen(log = nil)
    raise NotImplementedError.new("#{self.class}#reopen")
  end

  private

  def format_message(severity, datetime, progname, msg)
    raise NotImplementedError.new("#{self.class}#format_message")
  end

  def parse_severity(value)
    int_value = value.is_a?(Integer) ? value : (Integer(value.to_s) rescue nil)
    return int_value if SEVERITIES.values.include?(int_value)
    severity = value.to_s
    SEVERITIES[value.to_s.strip.downcase] || raise(ArgumentError.new("Invalid log severity: #{value.inspect}"))
  end

  def parse_severities_with_operator(value)
    if match = value.to_s.strip.match(/^([<>]=?)\s*(.+)$/)
      operator = match[1]
      severity = parse_severity(match[2])
      return SEVERITIES.values.select { |l| l.send(operator, severity) }
    end
    [parse_severity(value)]
  end

end

class Logger::LogDevice

  attr_accessor :formatter

end

require 'multiple_devices_logger/ignore_exceptions'

MultipleDevicesLogger.send(:include, MultipleDevicesLogger::IgnoreExceptions)
Logger::LogDevice.send(:include, MultipleDevicesLogger::IgnoreExceptions)
