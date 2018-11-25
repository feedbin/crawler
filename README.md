Refresher
=========

Refresher is a service meant to be run in combination with [Feedbin](https://github.com/feedbin/feedbin).

Refresher consists of a single Sidekiq job that

- Fetches and parses RSS feeds
- Checks for the existence of duplicates against a redis database
- Add new feed entries to redis to be imported back into Feedbin

Dependencies
------------

- Ruby 2.5
- Redis shared with main Feedbin instance
- You may need to install the development headers for libidn (`libidn11-dev` on Debian)

Installation
------------

**Install Redis**

    brew install redis

**Clone the repository**

    git clone https://github.com/feedbin/refresher.git && cd refresher

**Configure**

Refresher needs access to the same Redis instance as the main Feedbin instance (`REDIS_URL` environment variable). If using Feedbin to subscribe to twitter feeds, the `TWITTER_KEY` and `TWITTER_SECRET` environment variables also need to be available.

**Bundle**

     bundle

**Run**

     bundle exec foreman start     
     
