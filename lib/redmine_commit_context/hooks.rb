module RedmineCommitContext
  class Hooks < Redmine::Hook::ViewListener
    # Loads the plugin stylesheet only on the controllers that render one of
    # this plugin's views.
    STYLESHEET_CONTROLLERS = %w[issues versions commit_context/revisions].freeze

    def view_layouts_base_html_head(context = {})
      return '' unless STYLESHEET_CONTROLLERS.include?(context[:controller]&.controller_path)

      stylesheet_link_tag('commit_context', plugin: 'redmine_commit_context')
    end

    # Revisions for a version, shown on the version's own page. Paginated
    # like the filter page below -- a version tied to a whole sprint can
    # have hundreds of revisions.
    def view_versions_show_bottom(context = {})
      version = context[:version]
      return '' if version.nil?

      controller = context[:controller]
      view = context[:hook_caller]

      scope = RedmineCommitContext::RevisionScopes.for_version(version)
      changeset_count = scope.count
      changeset_pages = Paginator.new(changeset_count, controller.send(:per_page_option), controller.params[:page])
      changesets = scope.limit(changeset_pages.per_page).offset(changeset_pages.offset).to_a

      view.render(
        :partial => 'commit_context/version_revisions',
        :locals => {
          :version => version,
          :changesets => changesets,
          :changeset_count => changeset_count,
          :changeset_pages => changeset_pages
        }
      )
    end

    # "Show revisions for this filter" link in the issues index sidebar.
    # Deliberately checked here, before anything is rendered: a user with no
    # :view_changesets permission anywhere must never see the entry point.
    def view_issues_sidebar_queries_bottom(context = {})
      controller = context[:controller]
      return '' unless RedmineCommitContext::Permissions.revisions_visible_anywhere?(User.current, context[:project])

      view = context[:hook_caller]
      # project_id is a path segment on the project-scoped issues route, not
      # a query parameter, so it would otherwise be lost carrying the
      # filter over to the flat commit_context/revisions route.
      query_params = controller.request.query_parameters.except('page')
      query_params['project_id'] = context[:project].id if context[:project]

      view.render(
        :partial => 'commit_context/sidebar_link',
        :locals => { :query_params => query_params }
      )
    end
  end
end
