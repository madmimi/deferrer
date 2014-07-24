# setup redis
Deferrer.redis_config = { :host => "localhost", :port => 6379, db: 15 }

# define deferrer class (must have perform class method)
class NameDeferrer
  def perform(first_name, last_name)
    puts "#{first_name} #{last_name}".upcase
  end
end
