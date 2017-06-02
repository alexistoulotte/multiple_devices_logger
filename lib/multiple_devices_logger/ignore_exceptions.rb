class MultipleDevicesLogger

  module IgnoreExceptions

    extend ActiveSupport::Concern

    def exception_ignored?(exception)
      return false unless exception.is_a?(Exception)
      ignored_exception_classes.any? { |klass| exception.is_a?(klass) } || ignored_exceptions_procs.any? { |proc| proc.call(exception) }
    end

    def ignore_exceptions(*arguments, &block)
      @ignored_exception_class_names ||= []
      @ignored_exceptions_procs ||= []
      @ignored_exceptions_procs << Proc.new(&block) if block_given?
      [arguments].flatten.each do |argument|
        if argument.respond_to?(:call)
          @ignored_exceptions_procs << argument
        else
          klass = argument.is_a?(Class) ? argument : argument.to_s.presence.try(:constantize)
          raise("Invalid exception class: #{argument.inspect}") unless klass.is_a?(Class) && (klass == Exception || (klass < Exception))
          @ignored_exception_class_names << klass.name
        end
      end
      @ignored_exception_class_names.uniq!
      nil
    end

    def ignored_exception_classes
      (@ignored_exception_class_names || []).map(&:constantize)
    end

    def ignored_exceptions_procs
      @ignored_exceptions_procs || []
    end

  end

end
