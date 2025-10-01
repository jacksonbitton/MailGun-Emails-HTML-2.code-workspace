#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'json'

# Extract the template map from mailgun_mailer.rb without evaluating the file.
MAILER_PATH = File.expand_path('../mailgun_mailer.rb', __dir__)
MAILER_CONTENT = File.read(MAILER_PATH)

TEMPLATE_PATTERN = /^(\s*)([a-zA-Z0-9_]+):\s*'([^']+\.html)'/i.freeze

TEMPLATES = MAILER_CONTENT.scan(TEMPLATE_PATTERN).map do |_indent, key, path|
  [key.to_sym, path]
end.to_h.freeze

PLACEHOLDER_REGEX = /\{\{\s*([A-Za-z0-9_]+)\s*\}\}/.freeze

options = { format: :markdown }

OptionParser.new do |opts|
  opts.banner = 'Usage: ruby scripts/export_template_tokens.rb [options]'

  opts.on('-f', '--format FORMAT', 'Output format: markdown (default) or json') do |format|
    format = format.to_s.downcase.to_sym
    unless %i[markdown json].include?(format)
      warn 'FORMAT must be markdown or json'
      exit 1
    end
    options[:format] = format
  end

  opts.on('-o', '--output FILE', 'Write the output to FILE instead of STDOUT') do |file|
    options[:output] = file
  end
end.parse!

payload = TEMPLATES.sort_by { |key, _| key.to_s }.map do |key, relative_path|
  path = File.expand_path("../#{relative_path}", __dir__)
  html = File.read(path)
  tokens = html.scan(PLACEHOLDER_REGEX).flatten.map(&:strip).uniq.sort

  {
    key: key,
    template: relative_path,
    tokens: tokens,
    token_count: tokens.length
  }
end

output = case options[:format]
         when :json
           JSON.pretty_generate(payload)
         when :markdown
           payload.map do |entry|
             lines = []
             lines << "### #{entry[:key]}"
             lines << "*Template*: `#{entry[:template]}`"
             lines << "*Placeholders (#{entry[:token_count]} total)*:"
             entry[:tokens].each do |token|
               lines << "- `{{#{token}}}`"
             end
             lines << ''
             lines.join("\n")
           end.join("\n")
         else
           warn 'Unsupported format'
           exit 1
         end

if options[:output]
  File.write(options[:output], output)
else
  puts output
end
