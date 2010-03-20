# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

class EstimateTimelogController < ApplicationController
  menu_item :issues
  before_filter :find_project, :authorize, :only => [:edit, :destroy]
  before_filter :find_optional_project, :only => [:report, :details]

  verify :method => :post, :only => :destroy, :redirect_to => { :action => :details }
  
  helper :sort
  include SortHelper
  helper :issues
  include TimelogHelper
  helper :custom_fields
  include CustomFieldsHelper
  include EstimateTimelogHelper
  helper :issue_relations
  include IssueRelationsHelper 
 
  def report
      @combobox_criterias = { 'project' => "project",
                             'version' => "version",
                             'category' => "category",
                             'member' => "member",
                             'tracker' => "tracker",
                             'activity' => "activity",
                             'issue' => "issue",
                           }

      @available_criterias = { 'project' => {:sql => "project",
                                          :klass => Project,
                                          :label => :label_project},
                             'version' => {:sql => "version",
                                          :klass => Version,
                                          :label => :label_version},
                             'category' => {:sql => "category",
                                            :klass => IssueCategory,
                                            :label => :field_category},
                             'member' => {:sql => "member",
                                         :klass => User,
                                         :label => :label_member},
                             'tracker' => {:sql => "tracker",
                                          :klass => Tracker,
                                          :label => :label_tracker},
                             'activity' => {:sql => "activity",
                                           :klass => TimeEntryActivity,
                                           :label => :label_activity},
                             'issue' => {:sql => "issue",
                                         :klass => Issue,
                                         :label => :label_issue},
                             'start_date' => {:sql => "start_date",
                                         :klass => '',
                                         :label => :et_label_start_date},
                             'due_date' => {:sql => "due_date",
                                         :klass => '',
                                         :label => :et_label_due_date},
                             'done_ratio' => {:sql => "done_ratio",
                                         :klass => '',
                                         :label => :et_label_done_ratio}
                           }

    @available_criterias_yotei = { 'project' => {:sql => "issues.project_id",
                                          :klass => Project,
                                          :label => :label_project},
                             'version' => {:sql => "issues.fixed_version_id",
                                          :klass => Version,
                                          :label => :label_version},
                             'category' => {:sql => "issues.category_id",
                                            :klass => IssueCategory,
                                            :label => :field_category},
                             'member' => {:sql => "issues.assigned_to_id",
                                         :klass => User,
                                         :label => :label_member},
                             'tracker' => {:sql => "issues.tracker_id",
                                          :klass => Tracker,
                                          :label => :label_tracker},
                             'activity' => {:sql => "''",
                                           :klass => TimeEntryActivity,
                                           :label => :label_activity},
                             'issue' => {:sql => "issues.id",
                                         :klass => Issue,
                                         :label => :label_issue},
                             'start_date' => {:sql => "issues.start_date",
                                         :klass => '',
                                         :label => :et_label_start_date},
                             'due_date' => {:sql => "issues.due_date",
                                         :klass => '',
                                         :label => :et_label_due_date},
                             'done_ratio' => {:sql => "issues.done_ratio",
                                         :klass => '',
                                         :label => :et_label_done_ratio}
                           }

    @available_criterias_jisseki = { 'project' => {:sql => "time_entries.project_id",
                                          :klass => Project,
                                          :label => :label_project},
                             'version' => {:sql => "issues.fixed_version_id",
                                          :klass => Version,
                                          :label => :label_version},
                             'category' => {:sql => "issues.category_id",
                                            :klass => IssueCategory,
                                            :label => :field_category},
                             'member' => {:sql => "time_entries.user_id",
                                         :klass => User,
                                         :label => :label_member},
                             'tracker' => {:sql => "issues.tracker_id",
                                          :klass => Tracker,
                                          :label => :label_tracker},
                             'activity' => {:sql => "time_entries.activity_id",
                                           :klass => TimeEntryActivity,
                                           :label => :label_activity},
                             'issue' => {:sql => "time_entries.issue_id",
                                         :klass => Issue,
                                         :label => :label_issue},
                             'start_date' => {:sql => "issues.start_date",
                                         :klass => '',
                                         :label => :et_label_start_date},
                             'due_date' => {:sql => "issues.due_date",
                                         :klass => '',
                                         :label => :et_label_due_date},
                             'done_ratio' => {:sql => "issues.done_ratio",
                                         :klass => '',
                                         :label => :et_label_done_ratio}
                           }

    # Add list and boolean custom fields as available criterias
    custom_fields = (@project.nil? ? IssueCustomField.for_all : @project.all_issue_custom_fields)
    custom_fields.select {|cf| %w(list bool).include? cf.field_format }.each do |cf|
      @available_criterias["cf_#{cf.id}"] = {:sql => "(SELECT c.value FROM #{CustomValue.table_name} c WHERE c.custom_field_id = #{cf.id} AND c.customized_type = 'Issue' AND c.customized_id = #{Issue.table_name}.id)",
                                             :format => cf.field_format,
                                             :label => cf.name}
    end if @project
    
    # Add list and boolean time entry custom fields
    TimeEntryCustomField.find(:all).select {|cf| %w(list bool).include? cf.field_format }.each do |cf|
      @available_criterias["cf_#{cf.id}"] = {:sql => "(SELECT c.value FROM #{CustomValue.table_name} c WHERE c.custom_field_id = #{cf.id} AND c.customized_type = 'TimeEntry' AND c.customized_id = #{TimeEntry.table_name}.id)",
                                             :format => cf.field_format,
                                             :label => cf.name}
    end

    # Add list and boolean time entry activity custom fields
    TimeEntryActivityCustomField.find(:all).select {|cf| %w(list bool).include? cf.field_format }.each do |cf|
      @available_criterias["cf_#{cf.id}"] = {:sql => "(SELECT c.value FROM #{CustomValue.table_name} c WHERE c.custom_field_id = #{cf.id} AND c.customized_type = 'Enumeration' AND c.customized_id = #{TimeEntry.table_name}.activity_id)",
                                             :format => cf.field_format,
                                             :label => cf.name}
    end
   
    if params[:tmpl_cond] == '1'
      @criterias = ["member", "activity", "issue"]
    elsif params[:tmpl_cond] == '2'
      @criterias = ["member", "issue"]
    elsif params[:tmpl_cond] == '3'
      @criterias = ["project", "member", "issue"]
    elsif params[:tmpl_cond] == '4'
      @criterias = ["project", "version", "member"]
    else
      @criterias = params[:criterias] || []
    end
    @criterias = @criterias.select{|criteria| @available_criterias.has_key? criteria}
    @criterias.uniq!
    @criterias = @criterias[0,3]

    @columns = (params[:columns] && %w(year month week day).include?(params[:columns])) ? params[:columns] : 'month'
    
    retrieve_date_range
    
    @issue_cols = [] 

    unless @criterias.empty?
      @column_tbl = ''
      if params[:est_type] == '1' 
        @column_tbl = 'yotei'
      elsif params[:est_type] == '2' 
        @column_tbl = 'jisseki'
      end
      sql_select_all = @criterias.collect{|criteria| @column_tbl +'.'+ @available_criterias[criteria][:sql] + " AS " + criteria}.join(', ')
      sql_group_by_all = @criterias.collect{|criteria| @column_tbl + '.' + @available_criterias[criteria][:sql]}.join(', ')

      sql_select_yotei = @criterias.collect{|criteria| @available_criterias_yotei[criteria][:sql] + " AS " + criteria}.join(', ')
      sql_group_by_yotei = @criterias.collect{|criteria| @available_criterias_yotei[criteria][:sql]}.join(', ')

      sql_select_jisseki = @criterias.collect{|criteria| @available_criterias_jisseki[criteria][:sql] + " AS " + criteria}.join(', ')
      sql_group_by_jisseki = @criterias.collect{|criteria| @available_criterias_jisseki[criteria][:sql]}.join(', ')

      if @criterias.index("issue") 
        @issue_cols = ["start_date","due_date","done_ratio"]
          sql_select_all       << ', ' + @issue_cols.collect{|col| @column_tbl +'.'+ @available_criterias[col][:sql] + " AS " + col}.join(', ')
          sql_group_by_all     << ', ' + @issue_cols.collect{|col| @column_tbl +'.'+ @available_criterias[col][:sql]}.join(', ')
          sql_select_yotei     << ', ' + @issue_cols.collect{|col| @available_criterias_yotei[col][:sql] + " AS " + col}.join(', ')
          sql_group_by_yotei   << ', ' + @issue_cols.collect{|col| @available_criterias_yotei[col][:sql]}.join(', ')
          sql_select_jisseki   << ', ' + @issue_cols.collect{|col| @available_criterias_jisseki[col][:sql] + " AS " + col}.join(', ')
          sql_group_by_jisseki << ', ' + @issue_cols.collect{|col| @available_criterias_jisseki[col][:sql]}.join(', ')
      end

      sql  = "SELECT "
      sql << "#{sql_select_all}, yotei.hours_est, jisseki.hours "
      sql << "FROM   "
      sql << "(SELECT #{sql_select_yotei}, issues.id as issue_id, "
      sql << "    '' as spent_on, SUM(estimated_hours) AS hours_est   "
      sql << "    FROM issues  "
      sql << "    LEFT JOIN projects ON issues.project_id = projects.id   "
      sql << "      WHERE 1=1"
      sql << "      AND (%s) " % @project.project_condition(Setting.display_subprojects_issues?) if @project
      sql << "      AND (%s) " % Project.allowed_to_condition(User.current, :view_time_entries)
      if params[:est_type] == '1' 
        sql << "     AND (start_date <= '%s' )" % [ActiveRecord::Base.connection.quoted_date(@to.to_time)]
        sql << "     AND (due_date   >= '%s' )" % [ActiveRecord::Base.connection.quoted_date(@from.to_time)]
        sql << "     AND (issues.assigned_to_id = '%s')" % [User.current.id] if params[:my_type]
      end
      sql << "    GROUP BY #{sql_group_by_yotei}, issues.id) yotei "
      if params[:est_type] == '1' 
        sql << "LEFT  "
      elsif params[:est_type] == '2' 
        sql << "RIGHT "
      end
      sql << "JOIN "
      sql << "(SELECT #{sql_select_jisseki}, issues.id as issue_id, '' as spent_on, SUM(hours) AS hours FROM time_entries  LEFT JOIN issues ON time_entries.issue_id = issues.id   "
      sql << "    LEFT JOIN       projects ON issues.project_id = projects.id "
      sql << "      WHERE 1=1"
      sql << "      AND (%s) " % @project.project_condition(Setting.display_subprojects_issues?) if @project
      sql << "      AND (%s) " % Project.allowed_to_condition(User.current, :view_time_entries)
      if params[:est_type] == '2' 
        sql << "     AND (spent_on BETWEEN '%s' AND '%s')" % [ActiveRecord::Base.connection.quoted_date(@from.to_time), ActiveRecord::Base.connection.quoted_date(@to.to_time)]
        sql << "     AND (time_entries.user_id = '%s')" % [User.current.id] if params[:my_type]
      end
      sql << "    group by #{sql_group_by_jisseki}, issues.id) jisseki "
      sql << "ON (yotei.issue_id=jisseki.issue_id)  "
      sql << "WHERE yotei.hours_est > 0 OR jisseki.hours > 0 "

      @hours = ActiveRecord::Base.connection.select_all(sql)
      @hours = @hours.map{|i| i['done_ratio'] = i['done_ratio']+'%' if i.has_key? 'done_ratio'; i}
      @total_hours = @hours.inject(0) {|s,k| s = s + k['hours'].to_f}
      @total_hours_est = @hours.inject(0) {|s,k| s = s + k['hours_est'].to_f}
      
    end
    
    respond_to do |format|
      format.html { render :layout => !request.xhr? }
      format.csv  { send_data(report_to_csv_est(@criterias, @issue_cols, @hours), :type => 'text/csv; header=present', :filename => 'timelog.csv') }
    end
  end
  
  def details

    retrieve_date_range
    
    if !@est_flg
        sort_init 'spent_on', 'desc'
        sort_update 'spent_on' => 'spent_on',
            'user' => 'user_id',
            'activity' => 'activity_id',
            'project' => "#{Project.table_name}.name",
            'issue' => 'issue_id',
            'hours' => 'hours'
        cond = ARCondition.new
        if @project.nil?
            cond << Project.allowed_to_condition(User.current, :view_time_entries)
        elsif @issue.nil?
            cond << @project.project_condition(Setting.display_subprojects_issues?)
        else
            cond << ["#{TimeEntry.table_name}.issue_id = ?", @issue.id]
        end

        if params[:my_type]
            cond << ["#{TimeEntry.table_name}.user_id = ?", User.current.id]
        end

        cond << ['spent_on BETWEEN ? AND ?', @from, @to]

        TimeEntry.visible_by(User.current) do
            respond_to do |format|
                format.html {
                    # Paginate results
                    @entry_count = TimeEntry.count(:include => :project, :conditions => cond.conditions)
                    @entry_pages = Paginator.new self, @entry_count, per_page_option, params['page']
                    @entries = TimeEntry.find(:all, 
                                              :include => [:project, :activity, :user, {:issue => :tracker}],
                                              :conditions => cond.conditions,
                                              :order => sort_clause,
                                              :limit  =>  @entry_pages.items_per_page,
                                              :offset =>  @entry_pages.current.offset)
                    @total_hours = TimeEntry.sum(:hours, :include => :project, :conditions => cond.conditions).to_f
                    render :layout => !request.xhr?
                }
                format.atom {
                    entries = TimeEntry.find(:all,
                                             :include => [:project, :activity, :user, {:issue => :tracker}],
                                             :conditions => cond.conditions,
                                             :order => "#{TimeEntry.table_name}.created_on DESC",
                                             :limit => Setting.feeds_limit.to_i)
                                             render_feed(entries, :title => l(:label_spent_time))
                }
                format.csv {
                    # Export all entries
                    @entries = TimeEntry.find(:all, 
                                              :include => [:project, :activity, :user, {:issue => [:tracker, :assigned_to, :priority]}],
                                              :conditions => cond.conditions,
                                              :order => sort_clause)
                                              send_data(entries_to_csv(@entries), :type => 'text/csv; header=present', :filename => 'timelog.csv')
                }
            end
        end
    elsif @est_flg
        sort_init 'start_date', 'desc'
        sort_update 'start_date' => 'start_date',
            'user' => 'user_id',
            'activity' => 'activity_id',
            'project' => "#{Project.table_name}.name",
            'issue' => 'issue_id',
            'estimated_hours' => 'estimated_hours'
        cond = ARCondition.new
        if @project.nil?
            cond << Project.allowed_to_condition(User.current, :view_time_entries)
        elsif @issue.nil?
            cond << @project.project_condition(Setting.display_subprojects_issues?)
        else
            cond << ["#{Issue.table_name}.id = ?", @issue.id]
        end

        if params[:my_type]
            cond << ["#{Issue.table_name}.assigned_to_id = ?", User.current.id]
        end

        cond << ['(start_date <= ?) AND (due_date   >= ? ) ', @to, @from]

            respond_to do |format|
                format.html {
                    # Paginate results
                    @entry_count = Issue.count(:include => :project, :conditions => cond.conditions)
                    @entry_pages = Paginator.new self, @entry_count, per_page_option, params['page']
                    @entries = Issue.find(:all, 
                                              :include => [:project, :author ],
                                              #:include => [:project, :user ],
                                              :conditions => cond.conditions,
                                              :order => sort_clause,
                                              :limit  =>  @entry_pages.items_per_page,
                                              :offset =>  @entry_pages.current.offset)
                    @total_hours = Issue.sum(:estimated_hours, :include => :project, :conditions => cond.conditions).to_f
                    render :layout => !request.xhr?
                }
                format.atom {
                    entries = Issue.find(:all,
                                             :include => [:project, :author],
                                             :conditions => cond.conditions,
                                             :order => "#{Issue.table_name}.created_on DESC",
                                             :limit => Setting.feeds_limit.to_i)
                                             render_feed(entries, :title => l(:label_spent_time))
                }
                format.csv {
                    # Export all entries
                    @entries = Issue.find(:all, 
                                              :include => [:project, :author],
                                              :conditions => cond.conditions,
                                              :order => sort_clause)
                                              send_data(entries_to_csv(@entries).read, :type => 'text/csv; header=present', :filename => 'timelog.csv')
                }
            end
    end
  end
  
  def edit
    (render_403; return) if @time_entry && !@time_entry.editable_by?(User.current)
    @time_entry ||= TimeEntry.new(:project => @project, :issue => @issue, :user => User.current, :spent_on => User.current.today)
    @time_entry.attributes = params[:time_entry]
    
    call_hook(:controller_estimate_timelog_edit_before_save, { :params => params, :time_entry => @time_entry })
    
    if request.post? and @time_entry.save
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default :action => 'details', :project_id => @time_entry.project
      return
    end    
  end
  
  def destroy
    (render_404; return) unless @time_entry
    (render_403; return) unless @time_entry.editable_by?(User.current)
    @time_entry.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to :back
  rescue ::ActionController::RedirectBackError
    redirect_to :action => 'details', :project_id => @time_entry.project
  end

private
  def find_project
    if params[:id]
      @time_entry = TimeEntry.find(params[:id])
      @project = @time_entry.project
    elsif params[:issue_id]
      @issue = Issue.find(params[:issue_id])
      @project = @issue.project
    elsif params[:project_id]
      @project = Project.find(params[:project_id])
    else
      render_404
      return false
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_optional_project
    if !params[:issue_id].blank?
      @issue = Issue.find(params[:issue_id])
      @project = @issue.project
    elsif !params[:project_id].blank?
      @project = Project.find(params[:project_id])
    end
    deny_access unless User.current.allowed_to?(:view_time_entries, @project, :global => true)
  end
  
  # Retrieves the date range based on predefined ranges or specific from/to param dates
  def retrieve_date_range
    @free_period = false
    @from, @to = nil, nil

    if params[:period_type] == '1' || (params[:period_type].nil? && !params[:period].nil?)
      case params[:period].to_s
      when 'today'
        @from = @to = Date.today
      when 'yesterday'
        @from = @to = Date.today - 1
      when 'current_week'
        @from = Date.today - (Date.today.cwday - 1)%7
        @to = @from + 6
      when 'last_week'
        @from = Date.today - 7 - (Date.today.cwday - 1)%7
        @to = @from + 6
      when '7_days'
        @from = Date.today - 7
        @to = Date.today
      when 'current_month'
        @from = Date.civil(Date.today.year, Date.today.month, 1)
        @to = (@from >> 1) - 1
      when 'last_month'
        @from = Date.civil(Date.today.year, Date.today.month, 1) << 1
        @to = (@from >> 1) - 1
      when '30_days'
        @from = Date.today - 30
        @to = Date.today
      when 'current_year'
        @from = Date.civil(Date.today.year, 1, 1)
        @to = Date.civil(Date.today.year, 12, 31)
      end
    elsif params[:period_type] == '2' || (params[:period_type].nil? && (!params[:from].nil? || !params[:to].nil?))
      begin; @from = params[:from].to_s.to_date unless params[:from].blank?; rescue; end
      begin; @to = params[:to].to_s.to_date unless params[:to].blank?; rescue; end
      @free_period = true
    else
      # default
    end
    
    @from, @to = @to, @from if @from && @to && @from > @to
    @from ||= (TimeEntry.minimum(:spent_on, :include => :project, :conditions => Project.allowed_to_condition(User.current, :view_time_entries)) || Date.today) - 1
    @to   ||= (TimeEntry.maximum(:spent_on, :include => :project, :conditions => Project.allowed_to_condition(User.current, :view_time_entries)) || Date.today)

    if params[:est_type] == '1' || params[:est_flg] == "true"
      @est_flg = true
    elsif params[:est_type] == '2' || params[:est_flg] == "false"
      @est_flg = false
    end
    @mine_flg = params[:my_type] || params[:mine_flg]
  end

end
