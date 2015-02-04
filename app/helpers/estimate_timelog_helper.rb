# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'iconv'

module EstimateTimelogHelper
  include ApplicationHelper

  def render_estimate_timelog_breadcrumb
    links = []
    links << link_to(l(:label_project_all), {:project_id => nil, :issue_id => nil})
    links << link_to(h(@project), {:project_id => @project, :issue_id => nil}) if @project
    if @issue
      if @issue.visible?
        links << link_to_issue(@issue, :subject => false)
      else
        links << "##{@issue.id}"
      end
    end
    breadcrumb links
  end

  # is active.
  def activity_collection_for_select_options(time_entry=nil, project=nil)
    project ||= @project
    if project.nil?
      activities = TimeEntryActivity.shared.active
    else
      activities = project.activities
    end

    collection = []
    if time_entry && time_entry.activity && !time_entry.activity.active?
      collection << [ "--- #{l(:actionview_instancetag_blank_option)} ---", '' ]
    else
      collection << [ "--- #{l(:actionview_instancetag_blank_option)} ---", '' ] unless activities.detect(&:is_default)
    end
    activities.each { |a| collection << [a.name, a.id] }
    collection
  end

  def select_hours(data, criteria, value)
  	if value.to_s.empty?
  		data.select {|row| row[criteria].blank?}
    else
    	data.select {|row| row[criteria].to_s == value}
    end
  end

  def sum_hours(data, is_child_only = true)
    sum = 0
    data.each do |row|
      if (is_child_only)
        sum += row['hours'].to_f
      else
        sum += row['hours_all'].to_f
      end
    end
    sum
  end

  def sum_hours_est(data, is_child_only = true)
    sum = 0
    data.each do |row|
      if (is_child_only)
        sum += row['hours_est'].to_f
      else
        sum += row['hours_est_all'].to_f
      end
    end
    sum
  end

  def get_issuescol(data, criteria, col)
    ret = ""
    data.each do |row|
      ret = row[col].to_s
    end
    ret
  end

  def options_for_period_select(value)
    options_for_select([[l(:label_all_time), 'all'],
                        [l(:label_today), 'today'],
                        [l(:label_yesterday), 'yesterday'],
                        [l(:label_this_week), 'current_week'],
                        [l(:label_last_week), 'last_week'],
                        [l(:label_last_n_days, 7), '7_days'],
                        [l(:label_this_month), 'current_month'],
                        [l(:label_last_month), 'last_month'],
                        [l(:label_last_n_days, 30), '30_days'],
                        [l(:label_this_year), 'current_year']],
                        value)
  end

  def entries_to_csv(entries)
    ic = Iconv.new(l(:general_csv_encoding), 'UTF-8')
    decimal_separator = l(:general_csv_decimal_separator)
    custom_fields = TimeEntryCustomField.find(:all)
    export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [l(:field_spent_on),
                 l(:field_user),
                 l(:field_activity),
                 l(:field_project),
                 l(:field_issue),
                 l(:field_tracker),
                 l(:field_subject),
                 l(:et_label_estimated_hours),
                 l(:et_label_hours),
                 l(:field_comments)
                 ]
      # Export custom fields
      headers += custom_fields.collect(&:name)

      csv << headers.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      # csv lines
      entries.each do |entry|
        if entry.is_a?(TimeEntry)
          fields = [format_date(entry.spent_on),
                    entry.user,
                    entry.activity,
                    entry.project,
                    entry.issue.id,
                    entry.issue.tracker,
                    entry.issue.subject,
                    entry.issue.estimated_hours.to_s.gsub('.', decimal_separator),
                    entry.hours.to_s.gsub('.', decimal_separator),
                    entry.comments
                    ]
        else
          # todo: bugs!
          fields = [format_date(entry.start_date),
                    entry.assigned_to_id,
                    nil,
                    entry.project,
                    entry.id,
                    entry.tracker,
                    entry.subject,
                    entry.estimated_hours.to_s.gsub('.', decimal_separator),
                    nil,
                    nil
                    ]
        end
        fields += custom_fields.collect {|f| show_value(entry.custom_value_for(f)) }

        csv << fields.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      end
    end
    export
  end

  # yet issue only
  def abstract_obj_from_criterias(criteria, value)
    if !value.blank? && k = @available_criterias[criteria][:klass]
      obj = k.find_by_id(value.to_i)
      if obj.is_a?(Issue)
        obj
      end
    end
  end

  def format_criteria_value(criteria, value, obj = nil)
    if value.blank?
      l(:label_none)
    elsif obj.is_a?(Issue)
        obj.visible? ? "#{obj.tracker} ##{obj.id}: #{obj.subject}" : "##{obj.id}"
    elsif k = @available_criterias[criteria][:klass]
      obj = k.find_by_id(value.to_i)
      if obj.is_a?(Issue)
        obj.visible? ? "#{obj.tracker} ##{obj.id}: #{obj.subject}" : "##{obj.id}"
      else
        obj
      end
    else
      format_value(value, @available_criterias[criteria][:format])
    end
  end

  def report_to_csv_est(criterias, issue_cols, hours)
    export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      # Column headers
      headers = criterias.collect {|criteria| l(@available_criterias[criteria][:label]) }
      headers << l(:et_label_estimated_hours)
      headers << l(:et_label_hours)
      issue_cols.each do |col|
        headers << l(@available_criterias[col][:label])
      end
      csv << headers.collect {|c| to_utf8(c) }
      # Content
      report_criteria_to_csv(csv, criterias, issue_cols, hours)
      # Total row
      row = [ l(:label_total) ] + [''] * (criterias.size - 1)
      total_est = 0
      total = 0
        sum_est = sum_hours_est(select_hours(hours, @columns, ''))
        total_est += sum_est
        sum = sum_hours(select_hours(hours, @columns, ''))
        total += sum
      row << "%.2f" %total_est
      row << "%.2f" %total
      csv << row.collect {|c| to_utf8(c) }
      #csv << row
    end
    export
  end

  def report_criteria_to_csv(csv, criterias, issue_cols, hours, level=0)
    hours.collect {|h| h[criterias[level]].to_s}.uniq.each do |value|
      hours_for_value = select_hours(hours, criterias[level], value)
      next if hours_for_value.empty?
      row = [''] * level
      row << to_utf8(format_criteria_value(criterias[level], value))
      row += [''] * (criterias.length - level - 1)
      total_est = 0
      total = 0
        sum_est = sum_hours_est(select_hours(hours_for_value, @columns, ''))
        total_est += sum_est
        sum = sum_hours(select_hours(hours_for_value, @columns, ''))
        total += sum
      row << "%.2f" %total_est
      row << "%.2f" %total
      if (criterias.length <= (level+1)) && issue_cols
        issue_cols.each do |col|
          row << get_issuescol(hours_for_value, @columns, col)
        end
      end
      csv << row

      if criterias.length > level + 1
        report_criteria_to_csv(csv, criterias, issue_cols, hours_for_value, level + 1)
      end
    end
  end

  def to_utf8(s)
    @ic ||= Iconv.new(l(:general_csv_encoding), 'UTF-8')
    begin; @ic.iconv(s.to_s); rescue; s.to_s; end
  end
end
