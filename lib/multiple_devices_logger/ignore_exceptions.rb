class MultipleDevicesLogger

  module IgnoreExceptions

    extend ActiveSupport::Concern

    def exception_ignored?(exception)
      exception.is_a?(Exception) && ignored_exception_classes.any? do |klass|
        exception.is_a?(klass)
      end
    end

    def ignore_exceptions(*classes)
      @ignored_exception_class_names ||= []
      [classes].flatten.each do |class_name|
        klass = class_name.is_a?(Class) ? class_name : class_name.to_s.presence.try(:constantize)
        raise("Invalid exception class: #{class_name.inspect}") unless klass.is_a?(Class) && (klass == Exception || (klass < Exception))
        @ignored_exception_class_names << klass.name
      end
      @ignored_exception_class_names.uniq!
      nil
    end

    def ignored_exception_classes
      (@ignored_exception_class_names || []).map(&:constantize)
    end

  end

end
