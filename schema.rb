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
       type varchar,
       code code,
       mood_code mood_code,
       effective_time ivl,
       title varchar,
       status varchar,
       --encounter attrs
       discharge_disposition_code varchar
     );

     create table patient_encounters (
       CHECK ( class_code = 'PatientEncounter')
     ) inherits (acts);

     create table act_relationships (
       target_id varchar,
       source_id varchar,
       type_code varchar
     );

     create table participations (
       type_code varchar,
       function_code varchar,
       time ivl,
       mode_code varchar,

       act_id varchar,
       role_id varchar
     );

     create table roles (
       id varchar primary key,
       class_code varchar,
       code code,
       name varchar,
       player_id varchar,
       scoper_id varchar,
       telecom varchar
     );

     create table entities (
       id varchar primary key,
       class_code varchar,
       type varchar,
       code code,
       determiner_code varchar,
       name varchar,

       -- person attrs
       race_code varchar
     );

     create table persons (
       CHECK ( class_code = 'Person')
     ) inherits (entities);

    SQL
  end

  def down
    execute <<-SQL
      drop table if exists persons;
      drop table if exists participations;
      drop table if exists roles;
      drop table if exists entities;
      drop table if exists act_relationships;
      drop table if exists patient_encounters;
      drop table if exists acts;
      drop type if exists ivl cascade;
      drop type if exists code;
      drop type if exists mood_code;
    SQL
  rescue => e
    p e
  end
end

SchemaMigration.new.tap {|m| m.down; m.up }
