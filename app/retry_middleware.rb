# frozen_string_literal: true

class Sidekiq::RetryMiddleware
  def call(worker, job, queue)
    worker.retry_count = job["retry_count"] if worker.respond_to?(:retry_count)
    yield
  end
end
