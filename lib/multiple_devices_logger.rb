require 'active_support/core_ext/array'
require 'active_support/core_ext/object'
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
    text = format_message(format_severity(severity), Time.now, progname, message)
    devices_for(severity).each do |device|
      device.write(text)
    end
    true
  end
  alias_method :log, :add

  def add_device(device, *severities)
    severities = [severities].flatten
    options = severities.extract_options!
    device = LogDevice.new(device, options) unless device.is_a?(LogDevice)
    if severities.empty?
      keys = SEVERITIES.values
    else
      keys = severities.map do |severity|
        severity.to_s.strip.downcase == 'default' ? :default : parse_severities_with_operator(severity)
      end.flatten.uniq
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

  def devices_for(severity)
    @devices[parse_severity(severity)] || @devices[:default] || []
  end

  def reopen(log = nil)
    raise NotImplementedError.new("#{self.class}#reopen")
  end

  private

  def parse_severity(value)
    int_value = value.is_a?(Fixnum) ? value : (Integer(value.to_s) rescue nil)
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
