require "mongoid"
require_relative "../models/user"

ENV["MONGOID_ENV"] = "development"
Mongoid.load!("config/mongoid.yml")

puts "Enter a username:"
username = gets.chomp

if User.where(username: username).exists?
  puts "User with that name already exists!"
  exit
end

puts "Enter a password:"
password = gets.chomp

if user = User.create!(username: username, password: password)
  puts "Successfuly created an account for #{username}"
else
  puts "Account creation was unsuccessful."
end
