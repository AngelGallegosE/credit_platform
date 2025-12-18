# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding users..."

# Create Admin User
admin = User.find_or_create_by!(email: 'admin@gmail.com') do |u|
  u.password = 'asdf1234'
  u.role = 'admin'
  u.full_name = 'admin admin'
end
puts "Admin user created: #{admin.email}"

# Create Normal User
user = User.find_or_create_by!(email: 'user@gmail.com') do |u|
  u.password = 'asdf1234'
  u.role = 'user'
  u.full_name = 'user user'
end
puts "Normal user created: #{user.email}"

puts "Seeding completed successfully!"
