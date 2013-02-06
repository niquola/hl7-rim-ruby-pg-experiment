require './connection.rb'
require 'activeuuid'
require 'logger'
require 'faker'
load './schema.rb'

module MOODS
  EVN = 'EVN'
end

module DT
  class Code
    def self.load(str)
      return nil unless str
      parts = str.gsub(/[()]/,'').split(',')
      self.new(code: parts.first, code_system: parts[1], code_system_name:parts[2], display_name: parts[3])
    end

    def self.dump(type)
      type.to_s
    end

    attr_accessor :code
    attr_accessor :code_system
    attr_accessor :code_system_name
    attr_accessor :display_name

    def initialize(attrs)
      self.code = attrs[:code]
      self.code_system = attrs[:code_system]
      self.code_system_name = attrs[:code_system_name]
      self.display_name = attrs[:display_name]
    end

    def to_s(*args)
      "(#{code},#{code_system},#{code_system_name},#{display_name})"
    end
  end
end

class Act < ActiveRecord::Base
  include ActiveUUID::UUID
  after_initialize :init_values
  before_save :default_values

  serialize :code, DT::Code

  has_many :inbound_relationships, class_name: 'ActRelationship', foreign_key: 'target_id'
  has_many :outbound_relationships, class_name: 'ActRelationship', foreign_key: 'source_id'
  has_many :participations

  protected

  after_initialize :init_values
  def init_values
    self.id ||= UUIDTools::UUID.random_create
    self.class_code ||= self.class.name
  end

  def default_values
  end
end

class ActRelationship < ActiveRecord::Base
  belongs_to :target, class_name: 'Act'
  belongs_to :source, class_name: 'Act'
end

class PatientEncounter < Act
  self.table_name = 'patient_encounters'

  def init_values
    super
    self.mood_code = ::MOODS::EVN
  end
end

class Participation < ActiveRecord::Base
  scope :subjects, ->{ self.where(type_code: 'SBJ') }
  belongs_to :act, class_name: 'Act'
  belongs_to :role, class_name: 'Role'
end

class Role < ActiveRecord::Base
  after_initialize :init_values
  def init_values
    self.id ||= UUIDTools::UUID.random_create
  end
  belongs_to :player, class_name: 'Entity'
  belongs_to :scoper, class_name: 'Role'
  has_many :participations
end


class Entity < ActiveRecord::Base
  after_initialize :init_values
  def init_values
    self.id ||= UUIDTools::UUID.random_create
  end
  has_many :roles
end

class Person < Entity
  def full_name
    "Mr. #{name}"
  end
end


10.times do |i|
  person = Person.create!(class_code: 'Person', name: Faker::Name.name, race_code: 'niger')
  pt = Role.create!(player: person, class_code: 'Patient')


  enc = PatientEncounter
  .create!(effective_time: '(2012-01-01,)', title: 'visit into ed', status: 'active')
  pt.participations.create!(type_code: 'SBJ', act: enc)

  code = DT::Code.new(code: 'xxx', code_system_name: 'Snomed CT')
  (rand(3)+1).times do
    dx = Act.create!(code: code,
		     class_code: 'Observation',
		     mood_code: 'EVN',
		     title: Faker::Lorem.sentence)

    enc.outbound_relationships.create!(type_code: 'RSON', target: dx)
  end


  room = Role.create!(class_code: 'SDLOC', name: "ICU #{i%2}")
  enc.participations.create!(type_code: 'LOC', role: room)
end

# enc = PatientEncounter
# .create!(effective_time: '(2012-02-01,)', title: 'visit into ICU', status: 'complete')
# pt.participations.create!(type_code: 'SBJ', act: enc)



pt = Role.where(class_code: 'Patient').first
pt.participations.where(type_code:'SBJ').includes(:act).each do |part|
  p part.act
end

ActiveRecord::Base.logger = Logger.new(STDOUT)
def render_enc(enc)
  puts enc.title + " " + enc.participations.find{|p| p.type_code=='LOC'}.role.name + ' ' + enc.effective_time

  puts "Diagnoses"

  enc.outbound_relationships.each do |rel|
    next unless rel.type_code ==  'RSON'
    puts "* #{rel.target.title}"
  end
end

#all active encounters
puts "\n\nCurrent visits"
PatientEncounter.where(status: 'active')
.joins(participations: :role)
.where("roles.name = 'ICU 1'")
.includes(participations: {role: [:player]}, outbound_relationships: [:target])
.each do |enc|

  name = enc.participations
  .find{|p| p.type_code == 'SBJ'}
  .role.player.full_name

  puts "\n##{name}"
  render_enc enc
end

#encouters for patient
