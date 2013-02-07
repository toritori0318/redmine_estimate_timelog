require 'redmine'

Redmine::Plugin.register :redmine_estimate_timelog do
  name 'Redmine Estimate Timelog plugin'
  author 'toritori0318'
  description 'This is a plugin for Redmine'
  version '0.4.1'
  requires_redmine :version_or_higher => '1.4.0'
  menu :top_menu, :redmine_estimate_timelog, {:controller => 'estimate_timelog', :action => 'report'}, :caption => :et_label_menu
end
