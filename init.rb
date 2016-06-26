require 'redmine'

Redmine::Plugin.register :redmine_estimate_timelog do
  name 'Redmine Estimate Timelog plugin'
  author 'toritori0318'
  description 'This is a plugin for Redmine'
  version '0.6.0'
  requires_redmine :version_or_higher => '3.0.0'
  menu :top_menu, :redmine_estimate_timelog, {:controller => 'estimate_timelog', :action => 'report'}, :caption => :et_label_menu
end
