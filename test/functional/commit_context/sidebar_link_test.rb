require_relative '../../test_helper'

# The "Show revisions for this filter" sidebar link is added by
# RedmineCommitContext::Hooks#view_issues_sidebar_queries_bottom. It must be
# gated the same way as CommitContextRevisionsController itself -- see
# commit_context/revisions_controller_test.rb for the controller-side half
# of this permission pair.
class CommitContextSidebarLinkTest < ActionController::TestCase
  tests IssuesController

  fixtures :projects, :users, :roles, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :projects_trackers,
           :enabled_modules, :enumerations

  def test_link_hidden_for_user_without_view_changesets_anywhere
    project = create_private_project
    user = create_user_in(project, :permissions => [:view_issues])
    @request.session[:user_id] = user.id

    get :index, :params => { :project_id => project.id }

    assert_response :success
    assert_select "a[href*='commit_context/revisions']", false
  end

  def test_link_shown_for_user_with_view_changesets
    project = create_private_project
    user = create_user_in(project, :permissions => [:view_issues, :view_changesets, :browse_repository])
    @request.session[:user_id] = user.id

    get :index, :params => { :project_id => project.id }

    assert_response :success
    assert_select "a[href*='commit_context/revisions']"
  end

  private

  def create_private_project
    project = Project.generate!(:is_public => false)
    project.trackers = Tracker.all
    project.save!
    project
  end

  def create_user_in(project, permissions:)
    user = User.generate!
    role = Role.generate!(:permissions => permissions)
    User.add_to_project(user, project, role)
    user
  end
end
