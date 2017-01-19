require 'active_support/core_ext/array'
require 'active_support/core_ext/object'
require 'logger'

class MultipleDevicesLogger < Logger

  LEVELS = {
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
    # TODO
  end

  def add_device(device, *levels)
    levels = [levels].flatten
    options = levels.extract_options!
    device = LogDevice.new(device, options) unless device.is_a?(LogDevice)
    if levels.empty?
      keys = LEVELS.values
    else
      keys = levels.map do |level|
        level.to_s.strip.downcase == 'default' ? :default : parse_levels_with_operator(level)
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

  def devices_for(level)
    @devices[parse_level(level)] || @devices[:default] || []
  end

  def reopen(log = nil)
    raise NotImplementedError.new("#{self.class}#reopen")
  end

  private

  def parse_level(value)
    int_value = value.is_a?(Fixnum) ? value : (Integer(value.to_s) rescue nil)
    return int_value if LEVELS.values.include?(int_value)
    level = value.to_s
    LEVELS[value.to_s.strip.downcase] || raise(ArgumentError.new("Invalid log level: #{value.inspect}"))
  end

  def parse_levels_with_operator(value)
    if match = value.to_s.strip.match(/^([<>]=?)\s*(.+)$/)
      operator = match[1]
      level = parse_level(match[2])
      return LEVELS.values.select { |l| l.send(operator, level) }
    end
    [parse_level(value)]
  end

end
