require 'deferrer'
require_relative './common'

3.times do |i|
  Deferrer.defer_in(i + 3, 'identifier', NameDeferrer, 'User', '1')
end
