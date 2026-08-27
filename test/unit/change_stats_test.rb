require_relative '../test_helper'

class ChangeStatsTest < ActiveSupport::TestCase
  fixtures :changesets, :changes, :repositories, :projects

  def test_for_changesets_returns_empty_hash_for_empty_input
    assert_equal({}, RedmineCommitContext::ChangeStats.for_changesets([]))
  end

  def test_for_changesets_counts_added_and_modified
    changesets = Changeset.where(id: [100, 101]).to_a
    stats = RedmineCommitContext::ChangeStats.for_changesets(changesets)

    assert_equal({ added: 2, modified: 0, deleted: 0 }, stats[100])
    assert_equal({ added: 0, modified: 1, deleted: 0 }, stats[101])
  end

  def test_for_changesets_with_zero_filechanges
    changeset = Changeset.find(102)
    stats = RedmineCommitContext::ChangeStats.for_changesets([changeset])

    assert_nil stats[102]
  end

  def test_for_changesets_issues_a_single_query
    changesets = Changeset.where(id: [100, 101, 102]).to_a

    query_count = count_queries { RedmineCommitContext::ChangeStats.for_changesets(changesets) }
    assert_equal 1, query_count
  end

  private

  def count_queries
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:sql] =~ /\A\s*(BEGIN|COMMIT|SAVEPOINT|RELEASE)/i }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
      yield
    end
    count
  end
end
