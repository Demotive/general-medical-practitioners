#!/usr/bin/env ruby

require "csv"
require "json"

class Practitioner
  def initialize(data)
    @data = data
  end

  def general_medical_practitioner_code
    gmc_number
  end

  def matched_record?
    data.has_key?("GMCNumber") && data.has_key?("OrganisationCode")
  end

  def has_sensible_gmc_number?
    !%w(0000000 1234567).include?(gmc_number) && gmc_number =~ /[0-9]{7}/
  end

  def gp?
    data.fetch("JobTitle") == "General Practitioner"
  end

  def to_hash
    {
      general_medical_practitioner_code: general_medical_practitioner_code,
      name: title_cased_name,
      practice: practice_reference,
    }
  end

private
  attr_reader :data

  def title_cased_name
    untitled_name.gsub(/\b[A-Z]{2,}\b/, &:capitalize)
  end

  def untitled_name
    stripped_name.sub(/^Dr\.? /, "")
  end

  def stripped_name
    cleaned_name.gsub(/\s{2,}/, " ").strip
  end

  def cleaned_name
    name.sub(/\([mf]\)/i, "")
  end

  def name
    [
      data.fetch("GivenName"),
      data.fetch("FamilyName"),
    ].join(" ")
  end

  def practice_reference
    "general-medical-practice:#{practice_code}"
  end

  def practice_code
    data.fetch("OrganisationCode")
  end

  def gmc_number
    data.fetch("GMCNumber")
  end
end

def usage_message
  "Usage: #{$0} choices_staff_file.csv choices_practice_file.csv"
end

def load_choices_csv(file_name)
  CSV.read(file_name, col_sep: "\u00AC", quote_char: "\x00", encoding: "ISO-8859-1", headers: true).map(&:to_hash)
end

choices_staff_file = ARGV.fetch(0) { abort(usage_message) }
choices_practice_file = ARGV.fetch(1) { abort(usage_message) }

choices_practice_data = load_choices_csv(choices_practice_file).each.with_object({}) { |row, hash|
  hash[row.fetch("OrganisationID")] = row
}

choices_staff_data = load_choices_csv(choices_staff_file)

choices_data = choices_staff_data.map { |row|
  choices_practice_data.fetch(row.fetch("OrganisationID"), {}).merge(row)
}

practitioner_data = choices_data
  .map(&Practitioner.method(:new))
  .select(&:matched_record?)
  .select(&:gp?)
  .select(&:has_sensible_gmc_number?)
  .sort_by(&:general_medical_practitioner_code)

puts JSON.pretty_generate(
  practitioner_data.map(&:to_hash).uniq,
  indent: "    ",
)
