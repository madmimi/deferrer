![Travis status](https://travis-ci.org/madmimi/deferrer.png)

# Deferrer

Deferrer is a library for deferring work units for a time period or to a specific time. When time reaches, only the last work unit will be processed. Usually, the last work unit should be the one that summarizes all the previous ones. An example scenario would be sending live updates that happen *very* frequently and we want to limit them by sending an update every x seconds.

## Installation

Add this line to your application's Gemfile:

```
gem 'deferrer'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install deferrer
```


## Usage

Configure deferrer (redis connection, logger)

```ruby
Deferrer.redis_config = { :host => "localhost", :port => 6379 }
Deferrer.logger = Logger.new(STDOUT)
```


Define Deferrer worker (must respond to peform method):

```ruby
class WorkDeferrer
  include Deferrer::Worker

  def perform(*args)
  end
end
```

Deferrer is usually used in combination with background processing tools like sidekiq and resque where the Deferrer worker is a light-weight worker that just pushed jobs on the queue.


Start the runner.

```ruby
Deferrer.run(options = {})

# Following `options` are available:
#   loop_frequency - sleep between loops, default to 0.1 seconds
#   single_run     - process items only for a single loop, useful for testing
#   ignore_time    - don't wait for time period to expire, useful for testing
```

Defer some executions:

```ruby
WorkDeferrer.perform_in(5, 'identifier', 'update 1')
WorkDeferrer.perform_in(6, 'identifier', 'update 2')
WorkDeferrer.perform_in(9, 'identifier', 'update 3')
```


It will stack all defered work units per identifier until first timeout expires (5 seconds) and then it will only process the last update for the expired identifier, calling the deferrer worker:

```ruby
WorkDeferrer.new.perform('update 3')
```


## Testing

For testing, there are two options: single run and inline mode:

If you need to test in integration that the last update is processed use:

```ruby
# single_run - run the loop only once
# ignore_time - process the job now, don't wait for time period to expire
Deferrer.run(single_run: true, ignore_time: true)
```

Alternativelly, if you want to process all updates, just use inline mode:

```ruby
Deferrer.inline = true
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
