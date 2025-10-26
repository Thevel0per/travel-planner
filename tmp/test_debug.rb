require_relative 'config/environment'

user = User.create!(email: 'test@test.com', password: 'password123', password_confirmation: 'password123')
trip = Trip.create!(user: user, name: 'Test', destination: 'Test', start_date: Date.today, end_date: Date.today + 1, number_of_people: 1)

begin
  dto = DTOs::TripDTO.from_model_with_counts(trip)
  puts "DTO created: #{dto.inspect}"
  puts "Serialize: #{dto.serialize.inspect}"
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(5)
end
