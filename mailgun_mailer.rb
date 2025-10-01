class MailgunMailer
  def new_user_welcome_email(user)
    variables = {
      user_fullname: user.full_name,
      company: user.company.name,
      link: "#{ENV.fetch('ENV_URL', nil)}/login"
    }

    email = {}

    email[:from] = "WashUp Solutions <no-reply@#{ENV.fetch('MAILGUN_DOMAIN', nil)}>"
    email[:to] = user.email
    email[:subject] = 'Welcome to Wash Up'
    email[:template] = 'new user welcome email'
    email['h:Reply-To'] = 'help@washup.solutions'
    email['h:X-Mailgun-Variables'] = variables.to_json

    RestClient.post "https://api:#{ENV.fetch('MAILGUN_API_KEY', nil)}" \
                    "@api.mailgun.net/v3/#{ENV.fetch('MAILGUN_DOMAIN', nil)}/messages", email
  end

  def password_reset(to_email, customer_name, reset_token)
    reset_url = "#{ENV.fetch('MAILGUN_POSTBACK_URL', nil)}/password/reset/#{reset_token}"

    email = {}

    email[:from] = "WashUp Solutions <no-reply@#{ENV.fetch('MAILGUN_DOMAIN', nil)}>"
    email[:to] = to_email
    email[:subject] = 'Password Reset'
    email[:template] = 'Password Reset'
    email['h:Reply-To'] = 'help@washup.solutions'
    email['h:X-Mailgun-Variables'] = { customer_name: customer_name, reset_url: reset_url }.to_json

    # generate and send a reset key

    RestClient.post "https://api:#{ENV.fetch('MAILGUN_API_KEY', nil)}" \
                    "@api.mailgun.net/v3/#{ENV.fetch('MAILGUN_DOMAIN', nil)}/messages", email
  end

  def new_incident_created(incident)
    location = incident.location

    variables = {
      location_name: location.name,
      user_name: incident.user&.full_name || 'Deleted User',
      customer_name: incident.customer_name,
      incident_status: incident.status,
      under_review: true,
      link: "#{ENV.fetch('ENV_URL', nil)}/locations/#{location.id}/incidents/#{incident.id}/edit"
    }

    subject = "New Incident Created - #{variables[:location_name]} - " \
              "#{timezone_adjusted_date(incident.incident_date, incident.location)}"
    push_notification = "A new incident report was just created at #{variables[:location_name]} by " \
                        "#{variables[:user_name]} and is currently #{variables[:incident_status].upcase}."

    emails = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                       notification_type: UserNotification::TYPE_EMAIL, notification_category: 'incidents', notification_code: Notification::INCIDENTS_REVIEWED).pluck(:email)
    send_email(emails, subject, 'incident status', variables) unless emails.empty?

    ids = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                    notification_type: UserNotification::TYPE_MOBILE, notification_category: 'incidents', notification_code: Notification::INCIDENTS_REVIEWED).pluck(:id)
    send_push_notification(ids, push_notification) unless ids.empty?
  end

  def incident_status_change(incident)
    location = incident.location

    variables = {
      location_name: location.name,
      user_name: incident.user&.full_name || 'Deleted User',
      customer_name: incident.customer_name,
      incident_status: incident.status,
      under_review: false,
      link: "#{ENV.fetch('ENV_URL', nil)}/locations/#{location.id}/incidents/#{incident.id}/edit"
    }
    subject = "Incident Report #{variables[:incident_status]} - #{variables[:customer_name]} - #{variables[:location_name]}"
    push_notification = "The incident report status for #{variables[:customer_name]} at #{variables[:location_name]} has been updated to #{variables[:incident_status].upcase}."

    notification_code = ''
    case incident.status
    when 'In Progress'
      notification_code = Notification::INCIDENTS_IN_PROGRESS
    when 'Resolved'
      notification_code = Notification::INCIDENTS_RESOLVED
    when 'Denied'
      notification_code = Notification::INCIDENTS_RESOLVED
    end

    emails = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                       notification_type: UserNotification::TYPE_EMAIL, notification_category: 'incidents', notification_code: notification_code).pluck(:email)
    send_email(emails, subject, 'incident status', variables) unless emails.empty?

    ids = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                    notification_type: UserNotification::TYPE_MOBILE, notification_category: 'incidents', notification_code: notification_code).pluck(:id)
    send_push_notification(ids, push_notification) unless ids.empty?
  end

  def send_incident_details(emails, incident)
    variables = {
      customer_name: incident.customer_name,
      location_name: incident.location.name,
      user_fullname: incident.user&.full_name || 'Deleted User',
      reported_date: timezone_adjusted_date(incident.created_at, incident.location),
      status: incident.status,
      customer_phone: incident.phone,
      customer_email: incident.email,
      vehicle_vin: incident.vin,
      vehicle_year: incident.year,
      vehicle_make: incident.make,
      vehicle_model: incident.model,
      incident_date: timezone_adjusted_date(incident.incident_date, incident.location),
      incident_time: incident.incident_time,
      link: "#{ENV.fetch('ENV_URL', nil)}/locations/#{incident.location.id}/incidents/#{incident.id}/edit"
    }

    subject = "Incident Report Details for #{variables[:customer_name]} at #{variables[:location_name]} on #{variables[:incident_date]}."
    send_email(emails, subject, 'incident report', variables) unless emails.empty?
  end

  def assigned_to(user, location, item_type)
    variables = {
      location_name: location.name,
      user_fullname: user.full_name,
      item_type: item_type,
      link: "#{ENV.fetch('ENV_URL', nil)}/login"
    }

    subject = "You've been assigned to a new #{item_type} item."

    email_subscription = UserNotification.get_user_subscription_by(user_id: user.id, location_id: location.id,
                                                                   notification_type: UserNotification::TYPE_EMAIL, notification_category: Notification::GENERAL, notification_code: Notification::GENERAL)
    send_email([user.email], subject, 'assigned to', variables) if email_subscription

    push_subscription = UserNotification.get_user_subscription_by(user_id: user.id, location_id: location.id,
                                                                  notification_type: UserNotification::TYPE_MOBILE, notification_category: Notification::GENERAL, notification_code: Notification::GENERAL)
    send_push_notification([user.id], subject) if push_subscription
  end

  def overdue_tasks(location, tasks_count)
    variables = {
      location_name: location.name,
      tasks_count: tasks_count,
      link: "#{ENV.fetch('ENV_URL', nil)}/locations/#{location.id}/tasks/lists/all"
    }

    subject = "Past Due Tasks - #{location.name} - #{timezone_adjusted_date(Time.zone.yesterday, location)}"
    push_notification = "There were #{variables[:tasks_count]} tasks that were not completed yesterday at #{location.name} and are now Past Due."

    emails = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                       notification_type: UserNotification::TYPE_EMAIL, notification_category: 'tasks', notification_code: Notification::TASKS_PAST_DUE).pluck(:email)
    send_email(emails, subject, 'tasks - past due', variables) unless emails.empty?

    ids = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                    notification_type: UserNotification::TYPE_MOBILE, notification_category: 'tasks', notification_code: Notification::TASKS_PAST_DUE).pluck(:id)
    send_push_notification(ids, push_notification) unless ids.empty?
  end

  def new_today_task_created(location)
    variables = {
      location_name: location.name,
      link: "#{ENV.fetch('ENV_URL', nil)}/locations/#{location.id}/tasks/lists/todays"
    }

    subject = "A new task has been added to Today's Tasks at #{location.name}"
    push_notification = "A new task has been added to Today's Tasks at #{location.name} and needs to be completed today."

    emails = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                       notification_type: UserNotification::TYPE_EMAIL, notification_category: 'tasks', notification_code: Notification::TASKS_TODAY_TASK).pluck(:email)
    send_email(emails, subject, 'tasks - new today task', variables) unless emails.empty?

    ids = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                    notification_type: UserNotification::TYPE_MOBILE, notification_category: 'tasks', notification_code: Notification::TASKS_TODAY_TASK).pluck(:id)
    send_push_notification(ids, push_notification) unless ids.empty?
  end

  def task_list_completed(location, task_list)
    variables = {
      location_name: location.name,
      task_list_name: task_list.name,
      link: "#{ENV.fetch('ENV_URL', nil)}/locations/#{location.id}/tasks/lists/#{task_list.id}/tasks"
    }

    subject = "Task List Completed - #{location.name} - #{timezone_adjusted_date(Time.zone.today, location)}"
    push_notification = "The #{variables[:task_list_name]} at #{location.name} has been completed."

    emails = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                       notification_type: UserNotification::TYPE_EMAIL, notification_category: 'tasks', notification_code: Notification::TASKS_COMPLETED).pluck(:email)
    send_email(emails, subject, 'task list - complete', variables) unless emails.empty?

    ids = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                    notification_type: UserNotification::TYPE_MOBILE, notification_category: 'tasks', notification_code: Notification::TASKS_COMPLETED).pluck(:id)
    send_push_notification(ids, push_notification) unless ids.empty?
  end

  # email for a service reminder (currently just an integration proof of concept)
  def service_upcoming(service)
    location = service.location

    variables = {
      due_date: timezone_adjusted_date(service.due_date, location),
      location_name: location.name,
      service_item_name: service.equipment.name,
      link: "#{ENV.fetch('ENV_URL', nil)}/locations/#{location.id}/services/#{service.id}"
    }

    subject = "Upcoming Service - #{service.name} - #{location.name}"
    push_notification = "Reminder, the service item titled #{service.name} for #{location.name} is " \
                        "UPCOMING and is due on #{variables[:due_date]}."

    emails = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                       notification_type: UserNotification::TYPE_EMAIL, notification_category: 'services', notification_code: Notification::SERVICES_UPCOMING).pluck(:email)
    send_email(emails, subject, 'upcoming service', variables) unless emails.empty?

    ids = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                    notification_type: UserNotification::TYPE_MOBILE, notification_category: 'services', notification_code: Notification::SERVICES_UPCOMING).pluck(:id)
    send_push_notification(ids, push_notification) unless ids.empty?
  end

  def service_past_due(service)
    location = service.location

    variables = {
      due_date: timezone_adjusted_date(service.due_date, location),
      location_name: location.name,
      service_item_name: service.name,
      link: "#{ENV.fetch('ENV_URL', nil)}/locations/#{location.id}/services/#{service.id}"
    }

    subject = "Past Due Service - #{service.name} - #{location.name}"
    push_notification = "Attention! The service item titled #{service.name} for #{location.name} is PAST DUE and was due on #{variables[:due_date]}."

    emails = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                       notification_type: UserNotification::TYPE_EMAIL, notification_category: 'services', notification_code: Notification::SERVICES_PAST_DUE).pluck(:email)
    send_email(emails, subject, 'service — past due', variables) unless emails.empty?

    ids = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                    notification_type: UserNotification::TYPE_MOBILE, notification_category: 'services', notification_code: Notification::SERVICES_PAST_DUE).pluck(:id)
    send_push_notification(ids, push_notification) unless ids.empty?
  end

  def service_completed(service)
    location = service.location

    variables = {
      due_date: timezone_adjusted_date(service.completed_on, location),
      location_name: location.name,
      service_item_name: service.name,
      completed_by_name: service.completed_by&.name || 'Deleted User',
      link: "#{ENV.fetch('ENV_URL', nil)}/locations/#{location.id}/services/#{service.id}"
    }

    subject = "Service Completed - #{service.name} - #{location.name}"
    push_notification = "Service Completion: #{variables[:service_item_name]} for #{location.name} as been completed on #{variables[:due_date]} by #{variables[:completed_by_name]}."

    emails = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                       notification_type: UserNotification::TYPE_EMAIL, notification_category: 'services', notification_code: Notification::SERVICES_COMPLETED).pluck(:email)
    send_email(emails, subject, 'service - completed', variables) unless emails.empty?

    ids = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                    notification_type: UserNotification::TYPE_MOBILE, notification_category: 'services', notification_code: Notification::SERVICES_COMPLETED).pluck(:id)
    send_push_notification(ids, push_notification) unless ids.empty?
  end

  def inspection_attention_item(emails, inspections_equipment)
    equipment = inspections_equipment.equipment
    location = equipment.location
    reported_message = inspections_equipment.notes.empty? ? '' : inspections_equipment.notes.last.content

    variables = {
      location_name: location.name,
      user_name: inspections_equipment.reported_by.full_name,
      reported_datetime: timezone_adjusted_date_for_with_time(inspections_equipment.reported_on, location),
      status: inspections_equipment.status,
      equipment: equipment.name,
      bay: equipment.bay.name,
      reported_message: reported_message
    }

    subject = "Attention Item (#{inspections_equipment.id}) - #{equipment.name} - #{equipment.bay.name} - #{location.name}"
    emails = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                       notification_type: UserNotification::TYPE_EMAIL, notification_category: 'inspections', notification_code: Notification::INSPECTIONS_NEEDS_ATTENTION).pluck(:email)
    send_email(emails, subject, 'attention item', variables) unless emails.empty?
  end

  def inspection_completed(items)
    location = items.first.equipment.location
    bay = items.first.equipment.bay
    inspection_info = items.first

    action_items = []
    items.each do |item|
      action_items << { item: item.equipment.name, bay: bay.name, status: item.status }
    end

    subject = "Inspection Report - Attention Needed - #{location.name}"

    variables = {
      location_name: location.name,
      user_name: inspection_info.reported_by.full_name,
      inspection_name: inspection_info.inspection.name,
      items: action_items
    }

    emails = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                       notification_type: UserNotification::TYPE_EMAIL, notification_category: 'inspections', notification_code: Notification::INSPECTIONS_RESOLVED).pluck(:email)
    send_email(emails, subject, 'inspection completed', variables) unless emails.empty?

    # send onesignal
    ids = UserNotification.get_subscribed_users_by_(location_id: location.id,
                                                    notification_type: UserNotification::TYPE_MOBILE, notification_category: 'inspections', notification_code: Notification::INSPECTIONS_RESOLVED).pluck(:id)
    MobileappNotifications.new.send_notification(ids, subject)
  end

  def send_email(emails, subject, template, variables)
    email = {}

    email[:from] = "WashUp Solutions <no-reply@#{ENV.fetch('MAILGUN_DOMAIN', nil)}>"
    email[:to] = emails
    email[:subject] = subject
    email[:template] = template
    email['h:X-Mailgun-Variables'] = variables.to_json

    RestClient.post "https://api:#{ENV.fetch('MAILGUN_API_KEY', nil)}@api.mailgun.net/v3/#{ENV.fetch('MAILGUN_DOMAIN', nil)}/messages",
                    email
  end

  def send_push_notification(ids, notification)
    MobileappNotifications.new.send_notification(ids, notification)
  end

  def timezone_adjusted_date(date, location)
    date.in_time_zone(location.timezone).strftime('%b %e, %Y')
  end

  def timezone_adjusted_date_for_with_time(date, location)
    date.in_time_zone(location.timezone).strftime('%b %e, %Y at %l:%M %P')
  end

  def get_user_emails_by_role(location_id, role_array)
    UserLocation.joins(:user).where(location_id: location_id, role: role_array).pluck(:email)
  end

  def get_user_ids_by_role(location_id, role_array)
    UserLocation.joins(:user).where(location_id: location_id, role: role_array).pluck(:user_id)
  end

  def new_user_invitation_email(user_info, company_id)
    return if user_info[:email].blank? || user_info[:name].blank?

    company = Company.find(company_id)

    variables = {
      company_name: company.name,
      user_full_name: "#{user_info[:name]} #{user_info[:last_name]}".strip,
      link: InvitationLinkService.generate_invitation_link(user_info, company)
    }

    email = {}

    email[:from] = "WashUp Solutions <no-reply@#{ENV.fetch('MAILGUN_DOMAIN', nil)}>"
    email[:to] = user_info[:email]
    email[:subject] = "#{company.name} invited you to WashUp—create your account now"
    email[:template] = 'new user invitation email'
    email['h:Reply-To'] = 'help@washup.solutions'
    email['h:X-Mailgun-Variables'] = variables.to_json

    RestClient.post "https://api:#{ENV.fetch('MAILGUN_API_KEY', nil)}" \
                    "@api.mailgun.net/v3/#{ENV.fetch('MAILGUN_DOMAIN', nil)}/messages", email
  end
end
