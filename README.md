![Travis status](https://travis-ci.org/madmimi/deferrer.png)

# Deferrer

Deferrer is a library for deferring work units for a time period or to a specific time. When time reaches, only the last work unit will be run. Usually, the last work unit should be the one that summarizes all the previous ones. An example scenario would be when you want to send live updates to recipient, and if those updates happen *very* frequently, you would like to limit how often these updates are sent.

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

Configure redis

```ruby
Deferrer.redis_config = { :host => "localhost", :port => 6379 }
Deferrer.logger = Logger.new(STDOUT)
```


Define deferrer class (must include Deferrer::Job and have perform instance method)

```ruby
class Worker
  include Deferrer::Job

  def perform(update)
    puts update
  end
end
```


Start a worker process. It needs to have redis configured and access to deferrer classes.

```ruby
Deferrer.run(options = {})

# Following `options` are available:
#   loop_frequency - sleep between loops, default to 0.1 seconds
#   single_run     - process items only for a single loop, useful for testing
```


Defer some executions

```ruby
Deferrer.defer_in(5, 'identifier', Worker, 'update 1')
Deferrer.defer_in(6, 'identifier', Worker, 'update 2')
Deferrer.defer_in(9, 'identifier', Worker, 'update 3')
```


It will stack all defered executions per identifier until first timeout expires (5 seconds) and then it will only execute the last update for the expired identifier:

```ruby
Worker.new.perform('update 3')
```


## Testing

For testing, you can switch to inline mode and executions will not be deferred, but performed inline.

```ruby
Deferrer.inline = true
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
