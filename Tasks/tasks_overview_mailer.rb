def tasks_overview(location, date_range = nil)
    task_lists = fetch_task_lists(location)
    task_lists_html = generate_task_lists_html(task_lists, location)
    variables = prepare_tasks_overview_variables(location, date_range, task_lists_html)
    subject = "#{location.name} Daily Task Recap - #{variables[:date_range]}"
    emails = fetch_task_overview_emails(location)
    send_email(emails, subject, 'tasks overview', variables) unless emails.empty?
  end
  
  private
  
  def fetch_task_lists(location)
    TaskList.where(location: location).includes(:tasks)
  end
  
  def prepare_tasks_overview_variables(location, date_range, task_lists_html)
    {
      location_name: location.name,
      date_range: date_range || generate_date_range(location),
      task_lists_html: task_lists_html,
      manage_tasks_url: "#{ENV.fetch('ENV_URL', nil)}/locations/#{location.id}/tasks/lists/all",
      manage_preferences_url: "#{ENV.fetch('ENV_URL', nil)}/notifications/preferences"
    }
  end
  
  def fetch_task_overview_emails(location)
    UserNotification.get_subscribed_users_by_(
      location_id: location.id,
      notification_type: UserNotification::TYPE_EMAIL, 
      notification_category: 'tasks', 
      notification_code: Notification::TASKS_OVERVIEW
    ).pluck(:email)
  end
  
  def generate_task_lists_html(task_lists, location)
    return generate_no_tasks_message if task_lists.empty?
    
    html_parts = []
    
    task_lists.each_slice(2) do |pair|
      html_parts << '<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="margin-bottom: 0;">'
      html_parts << '<tr>'
      
      # First column - 49% width (leaves 2% for spacing between columns)
      html_parts << '<td style="width: 49%; vertical-align: top; padding-bottom: 16px; padding-right: 8px;">'
      html_parts << generate_task_card_html(pair[0], location)
      html_parts << '</td>'
      
      if pair.length == 2
        # Second column - 49% width with left padding
        html_parts << '<td style="width: 49%; vertical-align: top; padding-bottom: 16px; padding-left: 8px;">'
        html_parts << generate_task_card_html(pair[1], location)
        html_parts << '</td>'
      else
        # Empty column to maintain layout - 49% width
        html_parts << '<td style="width: 49%; padding-left: 8px;"></td>'
      end
      
      html_parts << '</tr>'
      html_parts << '</table>'
    end
    
    html_parts.join("\n")
  end
  
  def generate_task_card_html(task_list, location)
    total_tasks = task_list.tasks.count
    completed_tasks = calculate_completed_tasks_today(task_list)
    completion_percent = calculate_completion_percent(total_tasks, completed_tasks)
    progress_bar_html = generate_progress_bar_html(completion_percent)
    task_list_url = "#{ENV.fetch('ENV_URL', nil)}/locations/#{location.id}/tasks/lists/#{task_list.id}/tasks"
    
    <<~HTML
      <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" class="task-card" style="border: 1px solid #e8ebee; border-radius: 6px; background-color: #ffffff;">
        <tr>
          <td style="padding: 16px;">
            <p class="task-list-name" style="font-size: 16px; font-weight: 600; color: #141414; margin: 0 0 4px 0;">
              <a href="#{task_list_url}" class="apple-link" style="color: #141414; text-decoration: none;">#{task_list.name}</a>
            </p>
            <p class="task-stats" style="font-size: 14px; color: #667382; margin: 0 0 12px 0;">
              #{completed_tasks}/#{total_tasks} tasks completed
            </p>
            <p class="task-progress-percent" style="font-size: 13px; color: #667382; margin: 0 0 4px 0; font-weight: 500;">
              #{completion_percent}% Complete
            </p>
            #{progress_bar_html}
          </td>
        </tr>
      </table>
    HTML
  end
  
  def calculate_completed_tasks_today(task_list)
    today = Date.current
    task_list.tasks.where('completed_on >= ? AND completed_on < ?', 
                         today.beginning_of_day, 
                         today.end_of_day).count
  end
  
  def calculate_completion_percent(total_tasks, completed_tasks)
    return 0 if total_tasks.zero?
    ((completed_tasks.to_f / total_tasks) * 100).round
  end
  
  def generate_progress_bar_html(percentage)
    case percentage
    when 100
      # Green - fully complete
      <<~HTML
        <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="height: 6px; background-color: #{PROGRESS_BAR_COLOR_GREEN}; border-radius: 3px;">
          <tr>
            <td style="font-size: 0; line-height: 0;">&nbsp;</td>
          </tr>
        </table>
      HTML
    when 0
      # Light red - nothing complete
      <<~HTML
        <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="height: 6px; background-color: #F7D7D7; border-radius: 3px;">
          <tr>
            <td style="font-size: 0; line-height: 0;">&nbsp;</td>
          </tr>
        </table>
      HTML
    else
      # Yellow - partial completion
      <<~HTML
        <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="height: 6px; background-color: #{PROGRESS_BAR_COLOR_YELLOW_LIGHTEST}; border-radius: 3px;">
          <tr>
            <td style="width: #{percentage}%; background-color: #{PROGRESS_BAR_COLOR_YELLOW}; border-radius: 3px; font-size: 0; line-height: 0;">&nbsp;</td>
            <td style="width: #{100 - percentage}%; font-size: 0; line-height: 0;">&nbsp;</td>
          </tr>
        </table>
      HTML
    end
  end
  
  def generate_no_tasks_message
    <<~HTML
      <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="margin: 20px 0;">
        <tr>
          <td style="text-align: center; padding: 40px 20px;">
            <p style="font-size: 16px; color: #667382; margin: 0;">No task lists found for this location.</p>
          </td>
        </tr>
      </table>
    HTML
  end
  
  def generate_date_range(location)
    today = Time.current.in_time_zone(location.timezone)
    today.strftime('%A, %B %d, %Y')
  end