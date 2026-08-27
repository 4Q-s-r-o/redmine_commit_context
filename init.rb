require_relative 'lib/redmine_commit_context/hooks'

Redmine::Plugin.register :redmine_commit_context do
  name        'Commit context'
  author      'Martin Hlavňa (4Q)'
  description 'Kompaktné zobrazenie asociovaných revízií s identifikátorom repozitára, autorom a rozsahom zmien'
  version     '0.2.0'
  url         'https://github.com/<ORG>/redmine_commit_context'
  requires_redmine version_or_higher: '6.0.0'

  settings :default => { 'show_project_prefix' => '1' },
           :partial => 'settings/commit_context_settings'
end
