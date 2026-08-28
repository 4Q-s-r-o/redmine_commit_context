module CommitContext
  # Revisions for a version (params[:version_id]) or for an arbitrary issue
  # filter (query params, exactly like IssuesController#index). Filtering
  # itself is entirely delegated to IssueQuery -- this controller never
  # interprets filter params on its own, so saved queries, `query_id` and
  # ad-hoc URL filters (including cross-module tag filters) all work for
  # free.
  class RevisionsController < ApplicationController
    include QueriesHelper

    before_action :find_optional_project_or_version
    before_action :authorize_revisions

    accept_api_auth :index

    rescue_from Query::StatementInvalid, :with => :query_statement_invalid
    rescue_from Query::QueryError, :with => :query_error
    # base_scope (unlike IssueQuery#issues/#issue_count) does not translate
    # a malformed filter into Query::StatementInvalid itself.
    rescue_from ActiveRecord::StatementInvalid, :with => :query_statement_invalid

    helper :queries
    helper :repositories
    helper :issues

    def index
      if @version
        @changesets_scope = RedmineCommitContext::RevisionScopes.for_version(@version)
      else
        retrieve_query(IssueQuery, false)
        @changesets_scope =
          if @query.valid?
            RedmineCommitContext::RevisionScopes.for_issue_scope(@query.base_scope)
          else
            Changeset.none
          end
      end

      respond_to do |format|
        format.html do
          @changeset_count = @changesets_scope.count
          @changeset_pages = Paginator.new(@changeset_count, per_page_option, params[:page])
          @changesets = @changesets_scope.limit(@changeset_pages.per_page).offset(@changeset_pages.offset).to_a
          render :layout => !request.xhr?
        end
        format.csv do
          send_data(
            RedmineCommitContext::ChangesetsCsv.generate(@changesets_scope.to_a),
            :type => 'text/csv; header=present',
            :filename => 'revisions.csv'
          )
        end
      end
    end

    private

    # Resolves @project (used both for query scoping and for the permission
    # check below) from either params[:version_id] or params[:project_id],
    # same as IssuesController#index does via find_optional_project.
    def find_optional_project_or_version
      if params[:version_id].present?
        @version = Version.find(params[:version_id])
        @project = @version.project
      elsif params[:project_id].present?
        @project = Project.find(params[:project_id])
      end
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    # Independent of whether the sidebar link was shown: a direct hit on
    # this URL must be authorized on its own.
    def authorize_revisions
      return if performed?
      return if RedmineCommitContext::Permissions.revisions_visible_anywhere?(User.current, @project)

      deny_access
    end
  end
end
