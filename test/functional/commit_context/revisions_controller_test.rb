require_relative '../../test_helper'
require 'csv'

class CommitContext::RevisionsControllerTest < ActionController::TestCase
  tests CommitContext::RevisionsController

  fixtures :projects, :users, :roles, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :projects_trackers,
           :enabled_modules, :enumerations

  # --- Permissions -----------------------------------------------------

  def test_user_without_view_changesets_anywhere_gets_403
    project = create_private_project
    user = create_user_in(project, :permissions => [:view_issues])
    @request.session[:user_id] = user.id

    get :index, :params => { :project_id => project.id }

    assert_response 403
  end

  def test_direct_url_denied_even_though_link_would_not_have_been_shown
    # Mirrors the sidebar-visibility check in RedmineCommitContext::Hooks:
    # same permission, independently re-checked in the controller.
    project = create_private_project
    user = create_user_in(project, :permissions => [:view_issues])
    refute RedmineCommitContext::Permissions.revisions_visible_anywhere?(user, project)

    @request.session[:user_id] = user.id
    get :index, :params => { :project_id => project.id }

    assert_response 403
  end

  def test_anonymous_redirected_to_login_when_login_required
    with_settings :login_required => '1' do
      get :index
      assert_response :redirect
      assert_match %r{/login}, @response.redirect_url
    end
  end

  def test_anonymous_without_permission_redirected_to_login_when_login_not_required
    # The stock fixtures make project 1 public with view_changesets granted
    # to the builtin Anonymous role, which would otherwise make this
    # anonymous request legitimately succeed. Strip that out so the test
    # actually exercises "no permission anywhere".
    Role.anonymous.update!(:permissions => [])
    Role.non_member.update!(:permissions => [])

    with_settings :login_required => '0' do
      get :index
      assert_response :redirect
      assert_match %r{/login}, @response.redirect_url
    end
  end

  def test_user_with_permission_in_project_a_does_not_see_changesets_from_project_b
    project_a = create_private_project
    project_b = create_private_project
    user = create_user_in(project_a, :permissions => [:view_issues, :view_changesets, :browse_repository])
    # Same user can see issues in B, but has no repository permission there:
    # Changeset.visible must still hide B's changesets.
    add_user_to_project(user, project_b, :permissions => [:view_issues])

    issue_a, changeset_a = build_issue_with_changeset(project_a)
    issue_b, changeset_b = build_issue_with_changeset(project_b)

    @request.session[:user_id] = user.id
    get :index, :params => { :set_filter => '1', :status_id => '*' }

    assert_response :success
    assert_select "div#changeset-#{changeset_a.id}"
    assert_select "div#changeset-#{changeset_b.id}", false
  end

  # --- Functionality -----------------------------------------------------

  def test_changeset_linked_to_three_issues_appears_once_in_filter
    project = create_private_project
    user = create_user_in(project, :permissions => [:view_issues, :view_changesets, :browse_repository])
    repository = create_repository(project)
    changeset = create_changeset(repository)
    3.times { Issue.generate!(:project => project).changesets << changeset }

    @request.session[:user_id] = user.id
    get :index, :params => { :project_id => project.id, :set_filter => '1', :status_id => '*' }

    assert_response :success
    assert_select "div#changeset-#{changeset.id}", 1
  end

  def test_filter_via_saved_query_id
    project = create_private_project
    user = create_user_in(project, :permissions => [:view_issues, :view_changesets, :browse_repository])
    issue, changeset = build_issue_with_changeset(project)

    query = IssueQuery.new(:name => 'All', :project => project, :user => user,
                            :visibility => IssueQuery::VISIBILITY_PUBLIC)
    query.add_filter('status_id', '*', [])
    query.save!

    @request.session[:user_id] = user.id
    get :index, :params => { :query_id => query.id, :project_id => project.id }

    assert_response :success
    assert_select "div#changeset-#{changeset.id}"
  end

  def test_filter_via_ad_hoc_url_parameters
    project = create_private_project
    user = create_user_in(project, :permissions => [:view_issues, :view_changesets, :browse_repository])
    issue, changeset = build_issue_with_changeset(project)

    @request.session[:user_id] = user.id
    get :index, :params => {
      :project_id => project.id, :set_filter => '1',
      :f => ['status_id'], :op => { 'status_id' => '*' }, :v => {}
    }

    assert_response :success
    assert_select "div#changeset-#{changeset.id}"
  end

  def test_changeset_with_zero_filechanges_is_listed
    project = create_private_project
    user = create_user_in(project, :permissions => [:view_issues, :view_changesets, :browse_repository])
    issue, changeset = build_issue_with_changeset(project)

    @request.session[:user_id] = user.id
    get :index, :params => { :project_id => project.id, :set_filter => '1', :status_id => '*' }

    assert_response :success
    assert_select "div#changeset-#{changeset.id} .ccx-diff", false
  end

  def test_csv_export_has_same_row_count_as_html_list
    project = create_private_project
    user = create_user_in(project, :permissions => [:view_issues, :view_changesets, :browse_repository])
    repository = create_repository(project)
    changeset_1 = create_changeset(repository, :revision => '1001')
    changeset_2 = create_changeset(repository, :revision => '1002')
    Issue.generate!(:project => project).changesets << changeset_1
    Issue.generate!(:project => project).changesets << changeset_2

    @request.session[:user_id] = user.id
    get :index, :params => { :project_id => project.id, :set_filter => '1', :status_id => '*' }
    assert_select 'div.ccx-row', 2

    get :index, :params => { :project_id => project.id, :set_filter => '1', :status_id => '*', :format => 'csv' }
    assert_response :success
    rows = CSV.parse(@response.body)
    assert_equal 3, rows.size # header + 2 changesets
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

  def add_user_to_project(user, project, permissions:)
    role = Role.generate!(:permissions => permissions)
    User.add_to_project(user, project, role)
    user
  end

  def create_repository(project, identifier: 'app', url: 'file:///srv/git/app.git')
    Repository::Subversion.create!(
      :project_id => project.id, :identifier => identifier, :url => url,
      :root_url => url, :login => '', :password => ''
    )
  end

  def create_changeset(repository, comments: 'Fix the thing', revision: nil)
    Changeset.create!(
      :repository_id => repository.id, :committer => 'jsmith', :user_id => nil,
      :comments => comments, :revision => revision || rand(100_000..999_999).to_s,
      :committed_on => Time.now, :commit_date => Date.today
    )
  end

  def build_issue_with_changeset(project)
    repository = create_repository(project, :identifier => "repo-#{project.id}", :url => "file:///srv/git/#{project.identifier}.git")
    changeset = create_changeset(repository)
    issue = Issue.generate!(:project => project)
    issue.changesets << changeset
    [issue, changeset]
  end
end
