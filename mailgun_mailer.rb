# frozen_string_literal: true

require 'mailgun-ruby'

# MailgunMailer centralises the logic required to render and deliver
# transactional emails through Mailgun. Templates live in the HTML files that
# accompany this project and rely on simple "{{variable}}" placeholders that
# are replaced prior to delivery.
class MailgunMailer
  TEMPLATE_MAP = {
    incident_created: 'Incidents/incident_created.html',
    incident_under_review: 'Incidents/incident_under_review.html',
    incident_inprogress: 'Incidents/incident_inprogress.html',
    incident_resolved: 'Incidents/incident_resolved.html',
    incident_denied: 'Incidents/incident_denied.html',
    assigned_user: 'Other/assigned_user.html',
    new_user: 'Other/new_user.html',
    service_created: 'Services/service_created.html',
    service_pastdue: 'Services/service_pastdue.html',
    service_upcoming: 'Services/service-upcoming.html',
    service_upcoming_new: 'Services/service-upcoming-new.html',
    onetime_task_created: 'Tasks/onetime_task_created.html',
    task_list_completed: 'Tasks/task_list_completed.html'
  }.freeze

  attr_reader :client, :domain

  def initialize(api_key: ENV.fetch('MAILGUN_API_KEY'), domain: ENV.fetch('MAILGUN_DOMAIN'), client: nil)
    @client = client || Mailgun::Client.new(api_key)
    @domain = domain
    @token_cache = {}
  end

  # Deliver an email using one of the HTML templates.
  #
  # @param template [Symbol, String] key that maps to TEMPLATE_MAP
  # @param to [String, Array<String>] recipient email address(es)
  # @param subject [String] message subject line
  # @param variables [Hash] replacement variables for the template
  # @param from [String] sender email address (defaults to MAILGUN_FROM_ADDRESS env var)
  # @param cc [String, Array<String>, nil] optional CC recipients
  # @param bcc [String, Array<String>, nil] optional BCC recipients
  # @param reply_to [String, nil] optional Reply-To header value
  # @param text [String, nil] optional plaintext body to accompany the HTML
  # @param additional_params [Hash] optional Mailgun parameters (attachments, tags, etc.)
  # @return [Mailgun::Response]
  def send_email(template, to:, subject:, variables:, from: default_from, cc: nil, bcc: nil, reply_to: nil, text: nil, additional_params: {})
    html = render_template(template, variables)

    message = {
      from: from,
      to: array_wrap(to).join(','),
      subject: subject,
      html: html
    }

    message[:text] = text if text
    message[:cc] = array_wrap(cc).join(',') if cc
    message[:bcc] = array_wrap(bcc).join(',') if bcc
    message['h:Reply-To'] = reply_to if reply_to
    message.merge!(additional_params) if additional_params&.any?

    client.send_message(domain, message)
  end

  # Render the HTML template with the provided variables.
  #
  # @param template [Symbol, String]
  # @param variables [Hash]
  # @return [String] rendered HTML
  def render_template(template, variables = {})
    template_key = template.to_sym
    path = template_path(template_key)
    html = File.read(path)
    tokens = tokens_for(template_key) { extract_tokens(html) }

    replacements = normalise_keys(variables)
    missing = tokens.reject { |token| replacements.key?(token.downcase) }

    unless missing.empty?
      raise ArgumentError, "Missing variables for template '#{template_key}': #{missing.sort.join(', ')}"
    end

    output = html.dup
    replacements.each do |normalized_key, value|
      next unless (original_token = tokens_map(template_key)[normalized_key])

      output.gsub!(token_regex(original_token), value.to_s)
    end

    output
  end

  # Return the list of supported template keys.
  def available_templates
    TEMPLATE_MAP.keys
  end

  # Return the variables required by the specified template.
  def template_variables(template)
    tokens_for(template.to_sym)
  end

  private

  attr_reader :token_cache

  def template_path(template)
    relative = TEMPLATE_MAP.fetch(template) { raise ArgumentError, "Unknown template: #{template}" }
    File.expand_path(relative, __dir__)
  end

  def extract_tokens(html)
    html.scan(/\{\{\s*([A-Za-z0-9_]+)\s*\}\}/).flatten.uniq
  end

  def tokens_for(template)
    token_cache[template] ||= begin
      html = block_given? ? yield : File.read(template_path(template))
      tokens = extract_tokens(html)
      tokens_map(template).merge!(tokens.each_with_object({}) { |token, memo| memo[token.downcase] ||= token })
      tokens
    end
  end

  def tokens_map(template)
    token_cache["#{template}_map".to_sym] ||= {}
  end

  def normalise_keys(variables)
    variables.each_with_object({}) do |(key, value), memo|
      memo[key.to_s.downcase] = value
    end
  end

  def token_regex(token)
    /\{\{\s*#{Regexp.escape(token)}\s*\}\}/
  end

  def array_wrap(value)
    case value
    when nil then []
    when Array then value
    else
      value.to_s.split(',').map(&:strip)
    end
  end

  def default_from
    ENV.fetch('MAILGUN_FROM_ADDRESS', 'WashUp Solutions <no-reply@washup.solutions>')
  end
end
