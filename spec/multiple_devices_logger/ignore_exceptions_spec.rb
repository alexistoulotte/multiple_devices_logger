require 'spec_helper'

describe MultipleDevicesLogger::IgnoreExceptions do

  let(:object) { MultipleDevicesLogger.new }

  describe '#exception_ignored?' do

    it 'is true if exception is ignored' do
      expect {
        object.ignore_exceptions(NoMethodError)
      }.to change { object.exception_ignored?(NoMethodError.new) }.from(false).to(true)
    end

    it 'is false if exception is not ignored' do
      object.ignore_exceptions(IOError)
      expect(object.exception_ignored?(StandardError.new)).to be(false)
      expect(object.exception_ignored?(ArgumentError.new)).to be(false)
    end

    it 'is false if an invalid exception is given' do
      object.ignore_exceptions(IOError)
      expect(object.exception_ignored?(nil)).to be(false)
      expect(object.exception_ignored?('Hello')).to be(false)
    end

    it 'is correct with inheritance' do
      expect {
        object.ignore_exceptions(StandardError)
      }.to change { object.exception_ignored?(IOError.new) }.from(false).to(true)
    end

    it 'is true if block returns true' do
      object.ignore_exceptions(-> (e) { e.message =~ /BAM/ })
      expect(object.exception_ignored?(StandardError.new)).to be(false)
      expect(object.exception_ignored?(StandardError.new('BIM'))).to be(false)
      expect(object.exception_ignored?(StandardError.new('BIM BAM BIM'))).to be(true)
    end

  end

  describe '#ignore_exceptions' do

    it 'adds exception class to list' do
      expect {
        object.ignore_exceptions(StandardError)
      }.to change { object.ignored_exception_classes }.from([]).to([StandardError])
    end

    it 'accepts many exceptions' do
      expect {
        object.ignore_exceptions(ArgumentError, IOError)
      }.to change { object.ignored_exception_classes }.from([]).to([ArgumentError, IOError])
    end

    it 'accepts array' do
      expect {
        object.ignore_exceptions([ArgumentError, IOError])
      }.to change { object.ignored_exception_classes }.from([]).to([ArgumentError, IOError])
    end

    it 'accepts class names' do
      expect {
        object.ignore_exceptions(ArgumentError, 'IOError')
      }.to change { object.ignored_exception_classes }.from([]).to([ArgumentError, IOError])
    end

    it 'removes doubloons' do
      object.ignore_exceptions(IOError, ArgumentError)
      object.ignore_exceptions('IOError')
      expect(object.ignored_exception_classes).to eq([IOError, ArgumentError])
    end

    it 'returns nil' do
      expect(object.ignore_exceptions(StandardError)).to be_nil
    end

    it 'raise an error if an invalid class is given' do
      expect {
        object.ignore_exceptions(String)
      }.to raise_error('Invalid exception class: String')
    end

    it 'raise an error if nil is given' do
      expect {
        object.ignore_exceptions(nil)
      }.to raise_error('Invalid exception class: nil')
    end

    it 'raise an error if a blank string is given' do
      expect {
        object.ignore_exceptions(' ')
      }.to raise_error('Invalid exception class: " "')
    end

    it 'accepts a proc' do
      expect {
        object.ignore_exceptions(-> (e) { e.present? })
      }.to change { object.ignored_exceptions_procs.size }.by(1)
    end

    it 'accepts a block' do
      expect {
        object.ignore_exceptions { |e| e.present? }
      }.to change { object.ignored_exceptions_procs.size }.by(1)
    end

    it 'accepts a proc and a class' do
      expect {
        object.ignore_exceptions(-> (e) { e.present? }, StandardError)
      }.to change { object.ignored_exceptions_procs.size }.by(1)
    end

  end

  describe '#ignored_exception_classes' do

    it 'is exceptions ignored' do
      object.ignore_exceptions(ArgumentError, IOError)
      expect(object.ignored_exception_classes).to eq([ArgumentError, IOError])
    end

    it 'does not include procs' do
      object.ignore_exceptions(ArgumentError, Proc.new { })
      expect(object.ignored_exception_classes).to eq([ArgumentError])
    end

  end

  describe '#ignored_exceptions_procs' do

    it 'is exceptions proc ignored' do
      p = Proc.new { }
      expect {
        object.ignore_exceptions(p)
      }.to change { object.ignored_exceptions_procs }.from([]).to([p])
    end

  end

end
