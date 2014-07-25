require_relative './common'

10.times do |i|
  Deferrer.defer_in(2, i, Worker, 'update 1')
  Deferrer.defer_in(2, i, Worker, 'update 2')
  Deferrer.defer_in(2, i, Worker, 'update 3')
end
