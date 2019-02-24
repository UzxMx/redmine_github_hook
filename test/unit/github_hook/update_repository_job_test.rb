require 'test_helper'

class GithubHook::UpdateRepositoryJobTest < ActiveJob::TestCase
  def json
    # Sample JSON post from http://github.com/guides/post-receive-hooks
    '{
      "before": "5aef35982fb2d34e9d9d4502f6ede1072793222d",
      "repository": {
        "url": "http://github.com/defunkt/github",
        "name": "github",
        "description": "You\'re lookin\' at it.",
        "watchers": 5,
        "forks": 2,
        "private": 1,
        "owner": {
          "email": "chris@ozmm.org",
          "name": "defunkt"
        }
      },
      "commits": [
        {
          "id": "41a212ee83ca127e3c8cf465891ab7216a705f59",
          "url": "http://github.com/defunkt/github/commit/41a212ee83ca127e3c8cf465891ab7216a705f59",
          "author": {
            "email": "chris@ozmm.org",
            "name": "Chris Wanstrath"
          },
          "message": "okay i give in",
          "timestamp": "2008-02-15T14:57:17-08:00",
          "added": ["filepath.rb"]
        },
        {
          "id": "de8251ff97ee194a289832576287d6f8ad74e3d0",
          "url": "http://github.com/defunkt/github/commit/de8251ff97ee194a289832576287d6f8ad74e3d0",
          "author": {
            "email": "chris@ozmm.org",
            "name": "Chris Wanstrath"
          },
          "message": "update pricing a tad",
          "timestamp": "2008-02-15T14:36:34-08:00"
        }
      ],
      "after": "de8251ff97ee194a289832576287d6f8ad74e3d0",
      "ref": "refs/heads/master"
    }'
  end

  def repository
    return @repository if @repository

    @repository ||= Repository::Git.new
    @repository.stubs(:fetch_changesets).returns(true)
    @repository
  end

  def project
    return @project if @project

    @project ||= Project.new
    @project.repositories << repository
    @project
  end

  def setup
    Project.stubs(:find_by_identifier).with('github').returns(project)
  end

  def test_repository_is_updated
    GithubHook::Updater.any_instance.expects(:update_repository).returns(true)
    job = UpdateRepositoryJob.new(payload: json)
    message_logger = GithubHook::MessageLogger.new
    job.stubs(:logger).returns(message_logger)
    job.perform_now
    assert_match 'GithubHook: Redmine repository updated', message_logger.messages.map { |log| log[:message] }.join
  end
end
