require "rubygems"
require "bundler/setup"
require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  encoding: 'unicode',
  username: 'postgres',
  password: 'postgres',
  host: 'localhost',
  port: '5432',
  database: 'rimbaa'
)
