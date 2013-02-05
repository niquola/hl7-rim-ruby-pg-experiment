require './connection.rb'

class SchemaMigration < ActiveRecord::Migration
  def up
    execute <<-SQL
     CREATE TYPE mood_code AS ENUM ('EVN', 'REQ');
     CREATE TYPE code AS (
       code VARCHAR,
       code_system VARCHAR(256),
       code_system_name VARCHAR(256),
       display_name VARCHAR
     );

     CREATE TYPE ivl AS (
       low timestamp with time zone,
       height timestamp with time zone
     );

     create table acts (
       id varchar primary key,
       class_code varchar,
       code code,
       mood_code mood_code,
       effective_time ivl
     );

     create table act_relationships (
       target_id varchar,
       source_id varchar,
       type_code varchar
     );

     create table participation (
       type_code varchar,
       function_code varchar,
       time ivl,
       mode_code varchar
     );

     create table patient_encounters (
       discharge_disposition_code varchar
     ) inherits (acts);
    SQL
  end

  def down
    execute <<-SQL
      drop table if exists act_relationships;
      drop table if exists patient_encounters;
      drop table if exists acts;
      drop type if exists ivl;
      drop type if exists code;
      drop type if exists mood_code;
    SQL
  rescue => e
    p e
  end
end

SchemaMigration.new.tap {|m| m.down; m.up }
