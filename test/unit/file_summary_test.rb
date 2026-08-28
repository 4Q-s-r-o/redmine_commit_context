require_relative '../test_helper'

class FileSummaryTest < ActiveSupport::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :enabled_modules

  def test_empty_changesets_returns_empty_summary
    assert_equal [], RedmineCommitContext::FileSummary.for_changesets([])
  end

  def test_aggregates_distinct_file_paths_per_repository
    project = Project.generate!
    repository_a = create_repository(project, 'repo-a')
    repository_b = create_repository(project, 'repo-b')

    changeset_1 = create_changeset(repository_a, ['lib/a.rb', 'lib/b.rb'])
    changeset_2 = create_changeset(repository_a, ['lib/a.rb']) # same path touched again
    changeset_3 = create_changeset(repository_b, ['README.md'])

    entries = RedmineCommitContext::FileSummary.for_changesets([changeset_1, changeset_2, changeset_3])
    by_repo = entries.index_by { |entry| entry.repository.id }

    assert_equal 2, by_repo[repository_a.id].file_count # a.rb and b.rb, deduplicated
    assert_equal 1, by_repo[repository_b.id].file_count
    assert_equal 3, RedmineCommitContext::FileSummary.total_files(entries)
  end

  private

  def create_repository(project, identifier)
    Repository::Subversion.create!(
      :project_id => project.id, :identifier => identifier, :url => "file:///srv/git/#{identifier}.git",
      :root_url => "file:///srv/git/#{identifier}.git", :login => '', :password => ''
    )
  end

  def create_changeset(repository, paths)
    changeset = Changeset.create!(
      :repository_id => repository.id, :committer => 'jsmith',
      :comments => 'Fix', :revision => rand(100_000..999_999).to_s,
      :committed_on => Time.now, :commit_date => Date.today
    )
    paths.each do |path|
      Change.create!(:changeset_id => changeset.id, :action => 'M', :path => path)
    end
    changeset.reload
  end
end
