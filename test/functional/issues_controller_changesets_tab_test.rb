require_relative '../test_helper'

class IssuesControllerChangesetsTabTest < ActionController::TestCase
  tests IssuesController

  fixtures :projects, :users, :roles, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :projects_trackers,
           :enabled_modules, :enumerations

  def setup
    @user = User.find(2) # jsmith
    @request.session[:user_id] = @user.id
  end

  def test_repository_without_identifier_falls_back_to_url_basename_badge
    issue, changeset = build_issue_with_changeset(
      :repository_identifier => '', :repository_url => 'file:///srv/git/legacy-app.git'
    )

    get_changesets_tab(issue)

    assert_select "div#changeset-#{changeset.id} .ccx-badge", :text => 'legacy-app'
  end

  def test_changeset_without_mapped_user_falls_back_to_committer_string
    issue, changeset = build_issue_with_changeset(
      :committer => 'unmapped-committer <nobody@example.com>', :user_id => nil
    )

    get_changesets_tab(issue)

    assert_select "div#changeset-#{changeset.id} .ccx-author", :text => 'unmapped-committer'
  end

  def test_changeset_with_zero_filechanges_hides_diff_link
    issue, changeset = build_issue_with_changeset

    get_changesets_tab(issue)

    assert_select "div#changeset-#{changeset.id} .ccx-diff", false
  end

  def test_multiline_commit_message_shows_only_first_line
    issue, changeset = build_issue_with_changeset(
      :comments => "Fix the thing\n\nLonger explanation that should not appear"
    )

    get_changesets_tab(issue)

    assert_select "div#changeset-#{changeset.id} .ccx-message", :text => 'Fix the thing'
    assert_no_match(/Longer explanation/, @response.body)
  end

  def test_commit_message_with_html_is_escaped
    issue, changeset = build_issue_with_changeset(:comments => '<script>alert(1)</script> fix')

    get_changesets_tab(issue)

    assert_no_match(%r{<script>alert\(1\)</script>}, @response.body)
    assert_match(/&lt;script&gt;/, @response.body)
  end

  def test_two_repositories_with_same_basename_in_different_directories_are_both_shown
    project_a = create_project
    project_b = create_project
    repository_a = create_repository(project_a, :identifier => '', :url => 'file:///srv/git/team-a/shared.git')
    repository_b = create_repository(project_b, :identifier => '', :url => 'file:///srv/git/team-b/shared.git')
    changeset_a = create_changeset(repository_a, :comments => 'From team a', :revision => '1001')
    changeset_b = create_changeset(repository_b, :comments => 'From team b', :revision => '1002')

    issue = Issue.generate!(:project => project_a)
    issue.changesets << changeset_a
    issue.changesets << changeset_b

    get_changesets_tab(issue)

    assert_select "div#changeset-#{changeset_a.id}"
    assert_select "div#changeset-#{changeset_b.id}"
    assert_match(/2 revisions/, @response.body.gsub(/\s+/, ' '))
  end

  private

  # Builds a single-repository project, a changeset in it, and an issue
  # referencing that changeset. Each call uses a freshly generated project
  # so repository identifier uniqueness (scoped per project) never collides
  # with core's own fixtures or between test cases.
  def build_issue_with_changeset(repository_identifier: 'app', repository_url: 'file:///srv/git/app.git',
                                  committer: 'jsmith', user_id: 2, comments: 'Fix the thing', revision: nil)
    project = create_project
    repository = create_repository(project, :identifier => repository_identifier, :url => repository_url)
    changeset = create_changeset(
      repository, :committer => committer, :user_id => user_id, :comments => comments, :revision => revision
    )
    issue = Issue.generate!(:project => project)
    issue.changesets << changeset
    [issue, changeset]
  end

  def create_project
    project = Project.generate!
    project.trackers = Tracker.all
    project.save!
    User.add_to_project(@user, project, Role.find(1))
    project
  end

  def create_repository(project, identifier:, url: 'file:///srv/git/app.git')
    Repository::Subversion.create!(
      :project_id => project.id,
      :identifier => identifier,
      :url => url,
      :root_url => url,
      :login => '',
      :password => ''
    )
  end

  def create_changeset(repository, committer: 'jsmith', user_id: 2, comments: 'Fix the thing', revision: nil)
    Changeset.create!(
      :repository_id => repository.id,
      :committer => committer,
      :user_id => user_id,
      :comments => comments,
      :revision => revision || rand(100_000..999_999).to_s,
      :committed_on => Time.now,
      :commit_date => Date.today
    )
  end

  def get_changesets_tab(issue)
    get :issue_tab, :params => { :id => issue.id, :name => 'changesets' }, :xhr => true
    assert_response :success
  end
end
