require 'deferrer'
require_relative './common'

1.upto(5) do |i|
  WorkDeferrer.perform_in(i + 3, 'identifier', "update #{i}")
end
