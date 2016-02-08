#!/usr/bin/env ruby

require "csv"
require "json"

ODS_PRACTITIONER_HEADER = %w(
  organisation_code
  name
  national_grouping
  high_level_health_geography
  address_line_1
  address_line_2
  address_line_3
  address_line_4
  address_line_5
  postcode
  open_date
  close_date
  status_code
  organisation_sub_type_code
  parent_organisation_code
  join_parent_date
  left_parent_date
  contact_telephone_number
  null_1
  null_2
  null_3
  amended_record_indicator
  null_4
  current_care_organisation
  null_5
  null_6
  null_7
)

def usage_message
  "Usage: #{$0} ods_data_file.csv [amendment_file_1.csv ...]"
end

def load_ods_practitioners_csv(file_name)
  hash = {}

  CSV.read(file_name, headers: ODS_PRACTITIONER_HEADER).each { |row|
    hash[row.fetch("organisation_code")] = row.to_hash
  }

  hash
end

class Practitioner
  def initialize(ods_data)
    @ods_data = ods_data
  end

  def general_medical_practitioner_code
    ods_data.fetch("organisation_code")
  end

  def active?
    ods_data.fetch("status_code") == "A"
  end

  def locum?
    name.index("LOCUM")
  end

  def plausible_name?
    name =~ /^([-A-Z'\s]*)(\b[A-Z]{1,5})$/
  end

  def to_hash
    {
      general_medical_practitioner_code: general_medical_practitioner_code,
      name: formatted_name,
      practice: practice_reference,
    }
  end

private
  attr_reader :ods_data

  def formatted_name
    surname, *initials = name.split(/ /, -1)

    [
      *initials,
      surname.split(/\b/).map(&:capitalize).join,
    ].join(" ")
  end

  def name
    ods_data.fetch("name")
  end

  def practice_reference
    "general-medical-practice:#{practice_code}"
  end

  def practice_code
    ods_data.fetch("parent_organisation_code")
  end
end

ods_file = ARGV.fetch(0) { abort(usage_message) }
ods_amendments = ARGV.drop(1)
ods_data_files = [ods_file] + ods_amendments

ods_data = ods_data_files
  .map(&method(:load_ods_practitioners_csv))
  .reduce(&:merge)
  .values
  .lazy
  .map(&Practitioner.method(:new))
  .select(&:active?)
  .reject(&:locum?)
  .select(&:plausible_name?)
  .sort_by(&:general_medical_practitioner_code)

puts JSON.pretty_generate(
  ods_data.map(&:to_hash),
  indent: "    ",
)
