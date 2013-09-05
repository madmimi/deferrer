# Deferrer

Defer executions and run only the last update at the scheduled time



## Installation

Add this line to your application's Gemfile:

    gem 'deferrer'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install deferrer



## Usage

Configure redis

    Deferrer.redis_config = { :host => "localhost", :port => 6379 }


Define deferrer class (must have perform class method)

    class NameDeferrer
      def self.perform(first_name, last_name)
        puts "#{first_name} #{last_name}".upcase
      end
    end


Start a worker process. It needs to have redis configured and access to deferrer classes.

    Deferrer.run


Defer some executions

    Deferrer.defer_in(5, 'identifier', NameDeferrer, 'User', '1')
    Deferrer.defer_in(6, 'identifier', NameDeferrer, 'User', '2')
    Deferrer.defer_in(9, 'identifier', NameDeferrer, 'User', '3')


It will stack all defered executions per identifier until first timeout expires (5 seconds) and then it will only execute the last update for the expired identifier:

    NameDeferrer.perform('User', '3') => USER 3



## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
