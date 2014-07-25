require_relative './common'

puts 'Runner started'

Deferrer.run({
  :loop_frequency => 0.5
})
