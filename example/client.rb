require_relative './common'

10.times do |i|
  Deferrer.defer_in(2, i, Worker, 'First update')
  Deferrer.defer_in(2, i, Worker, 'Second update')
  Deferrer.defer_in(2, i, Worker, 'Last update')
end
