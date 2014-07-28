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


Define deferrer worker that must respond to call method

```ruby
Deferrer.worker = lambda do |klass, *args|
  # do some work
  # Resque.enqueue(klass, *args)
end
```

Deferrer is usually used in combination with background processing tools like sidekiq and resque. If that's the case, Deferrer.worker can be light-weight and responsible only for pushing work to a background job.


Start a worker process.

```ruby
Deferrer.run(options = {})

# Following `options` are available:
#   loop_frequency - sleep between loops, default to 0.1 seconds
#   single_run     - process items only for a single loop, useful for testing
#   ignore_time    - don't wait for time period to expire, useful for testing
```


Defer some executions:

```ruby
Deferrer.defer_in(5, 'identifier', Worker, 'update 1')
Deferrer.defer_in(6, 'identifier', Worker, 'update 2')
Deferrer.defer_in(9, 'identifier', Worker, 'update 3')
```


It will stack all defered executions per identifier until first timeout expires (5 seconds) and then it will only execute the last update for the expired identifier, calling the deferrer worker:

```ruby
Deferrer.worker.call('Worker', 'update 3')
```


## Testing

For testing, two options of the `run` method are useful. `single_run` will run the loop only once and `ignore_time` will not wait for time period to expire but execute to job now.

```ruby
Deferrer.run(single_run: true, ignore_time: true)
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
