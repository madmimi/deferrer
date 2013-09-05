# Deferrer

Schedule execution and then run only the last update at scheduled time

## Installation

Add this line to your application's Gemfile:

    gem 'deferrer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install deferrer

## Usage

Setup redis and deferrer classes

    # setup redis
    Deferrer.redis_config = { :host => "localhost", :port => 6379 }

    # define deferrer class (must have perform class method)
    class CarDeferrer
      def self.perform(car)
        p car.upcase
      end
    end

Start worker

    Deferrer.run

Defer some executions

    Deferrer.defer_in(5, 'car-1', CarDeferrer, 'car')
    Deferrer.defer_in(6, 'car-1', CarDeferrer, 'car')
    Deferrer.defer_in(9, 'car-1', CarDeferrer, 'car')


After 5 seconds, it will execute only once `CarDeferrer.perform('car')`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
