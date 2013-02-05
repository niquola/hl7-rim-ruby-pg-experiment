require './connection.rb'
require 'activeuuid'
require 'logger'
#ActiveRecord::Base.logger = Logger.new(STDOUT)

module MOODS
  EVN = 'EVN'
end

module DT
  class Code
    def self.load(str)
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

  protected

  def init_values
    self.id ||= UUIDTools::UUID.random_create
    self.class_code ||= self.class.name.underscore
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


act = Act.create(code: DT::Code.new(code: 'ControlAct', code_system_name: 'Home'))

enc = PatientEncounter
.create(code: DT::Code.new(code: 'Inpatient', code_system_name: 'Home'),
        effective_time: '(2012-01-01,2012-02-01)',
        discharge_disposition_code: 'Dispo')

#code: Inpatient | Meditech

enc.outbound_relationships.create(target: act, type_code: 'fullfillment')

enc = PatientEncounter
.where(["(code).code = 'Inpatient'"])
.first

p enc.code.code
p enc.outbound_relationships.first.target
p act.inbound_relationships.first.source

