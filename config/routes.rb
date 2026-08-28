# Redmine's own config/routes.rb loads every plugin's routes.rb via
# instance_eval *inside* its single top-level `draw do ... end` block (see
# the `Redmine::Plugin.directory.glob("*/config/routes.rb")` loop near the
# bottom of core's config/routes.rb). Wrapping this file in its own
# `RedmineApp::Application.routes.draw do ... end` would call
# ActionDispatch::Routing::RouteSet#draw a second time from inside itself,
# which calls `clear!` first -- wiping out every route defined before this
# plugin's routes.rb ran (i.e. all of core's routes). This file must
# contain bare route statements only.
get 'commit_context/revisions' => 'commit_context/revisions#index', :as => 'commit_context_revisions'
