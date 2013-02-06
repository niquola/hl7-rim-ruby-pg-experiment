require "rubygems"
require "bundler/setup"
require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  encoding: 'unicode',
  # username: 'postgres',
  # password: 'postgres',
  # host: 'localhost',
  host: '/home/nicola/pg',
  port: '5555',
  database: 'rimbaa'
)
