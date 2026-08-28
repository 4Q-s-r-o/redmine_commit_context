require_relative '../../test_helper'

# Function A: revisions embedded on the version's own page, via
# RedmineCommitContext::Hooks#view_versions_show_bottom.
class CommitContextVersionRevisionsHookTest < ActionController::TestCase
  tests VersionsController

  fixtures :projects, :users, :roles, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :projects_trackers,
           :enabled_modules, :enumerations

  def setup
    @project = Project.generate!
    @project.trackers = Tracker.all
    @project.save!
    @user = User.generate!
    role = Role.generate!(:permissions => [:view_issues, :view_changesets, :browse_repository])
    User.add_to_project(@user, @project, role)
    @request.session[:user_id] = @user.id
  end

  def test_version_without_issues_shows_empty_state
    version = Version.generate!(:project => @project)

    get :show, :params => { :id => version.id }

    assert_response :success
    assert_select 'div#ccx-version-revisions'
    assert_match(/no revisions/, @response.body)
  end

  def test_version_with_issues_but_no_changesets_shows_empty_state
    version = Version.generate!(:project => @project)
    Issue.generate!(:project => @project, :fixed_version => version)

    get :show, :params => { :id => version.id }

    assert_response :success
    assert_match(/no revisions/, @response.body)
  end

  def test_version_with_linked_changeset_is_listed
    version = Version.generate!(:project => @project)
    repository = create_repository(@project)
    changeset = create_changeset(repository)
    Issue.generate!(:project => @project, :fixed_version => version).changesets << changeset

    get :show, :params => { :id => version.id }

    assert_response :success
    assert_select "div#changeset-#{changeset.id}"
  end

  private

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
end
