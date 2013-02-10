if Rails::VERSION::MAJOR >= 3
  RedmineApp::Application.routes.draw do
    match '/estimate_timelog/:action', :controller => 'estimate_timelog', :via => [:get, :post]
    #match '/estimate_timelog/:action', :to => 'estimate_timelog#report'
  end
else
  ActionController::Routing::Routes.draw do |map|
    map.connect ':controller/:action'
  end
end

