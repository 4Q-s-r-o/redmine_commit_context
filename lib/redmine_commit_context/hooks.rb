module RedmineCommitContext
  class Hooks < Redmine::Hook::ViewListener
    # Loads the plugin stylesheet only on the issues controller, where the
    # associated-revisions tab this plugin overrides is rendered.
    def view_layouts_base_html_head(context = {})
      return '' unless context[:controller]&.controller_name == 'issues'

      stylesheet_link_tag('commit_context', plugin: 'redmine_commit_context')
    end
  end
end
