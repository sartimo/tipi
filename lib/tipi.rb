#!/usr/bin/env ruby

require 'tipi/parser'
require 'tipi/version'

module Tipi
  def self.text_to_html(text, options = {})
    Parser.new(text, options).to_html
  end
end
