require_relative './common'

puts 'Runner started'

Deferrer.run({
  :before_each    => lambda { LOGGER.info "before callback" },
  :after_each     => lambda { LOGGER.info "after callback" },
  :loop_frequency => 0.5
})
