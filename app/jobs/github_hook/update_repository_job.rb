class GithubHook::UpdateRepositoryJob < ActiveJob::Base
  def perform(params)
    updater = GithubHook::Updater.new(JSON.parse(params[:payload] || '{}'), params)
    updater.logger = logger
    updater.call
  end
end
