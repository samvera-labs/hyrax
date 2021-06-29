# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Hyrax::Engine.load_seed unless ActiveModel::Type::Boolean.new.cast(ENV["SKIP_HYRAX_ENGINE_SEED"])

puts "\n== Loading users"
User.where(email: 'admin@example.com').first_or_create do |f|
  f.password = 'admin_password'
end

User.where(email: 'basic_user@example.com').first_or_create do |f|
  f.password = 'password'
end

User.where(email: 'another_user@example.com').first_or_create do |f|
  f.password = 'password'
end
