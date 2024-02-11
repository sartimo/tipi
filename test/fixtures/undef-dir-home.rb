# frozen_string_literal: false

class Dir
  class << self
    prepend (Module.new do
      def home
        raise 'mimic failure' if caller[0].include? '/tipi.rb:'
        super
      end
    end)
  end
end
