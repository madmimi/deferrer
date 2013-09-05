# setup redis
Deferrer.redis_config = { :host => "localhost", :port => 6379 }

# define deferrer class (must have perform class method)
class NameDeferrer
  def self.perform(first_name, last_name)
    puts "#{first_name} #{last_name}".upcase
  end
end
