require 'optparse'
require 'pdfkit'
require 'tipi/parser'
require 'tipi/version'

module Tipi
  def self.text_to_html(text, options = {})
    Parser.new(text, options).to_html
  end

  def self.text_to_pdf()
    pdfkit = PDFKit.new(File.new(output_file))
    pdfkit.to_file('output.pdf')
  end
end

options = {}
OptionParser.new do |opts|
  opts.on("-i", "--input FILE", "Input file") do |input_file|
    options[:input_file] = input_file
  end
  opts.on("-o", "--output FILE", "Output file") do |output_file|
    options[:output_file] = output_file
  end
end.parse!

if options[:input_file].nil?
  puts "Please provide an input file using -i or --input option."
  exit(1)
end

input_file_content = File.read(options[:input_file])
html = Tipi.text_to_html(input_file_content)

output_file = options[:output_file] || "output.html"
File.open(output_file, "w") do |file|
  file.puts(html)
end

