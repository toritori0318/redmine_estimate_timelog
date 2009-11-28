require 'redmine'

Redmine::Plugin.register :redmine_estimate_timelog do
  name 'Redmine Estimate Timelog plugin'
  author 'toritori0318'
  description 'Plan/results report indication plugin'
  version '0.1.0'
  menu :top_menu, :redmine_estimate_timelog, {:controller => 'estimate_timelog', :action => 'report'}, :caption =>   :et_label_menu, :last => true
end
