require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_home_phone(home_phone)
  # Scans for digits and joins it as new string
  home_phone = home_phone.scan(/\d/).join

  # Checks valid number condition
  if home_phone.to_s.length == 11 && home_phone.to_s[0] == '1'
    home_phone[1..]
  elsif home_phone.to_s.length == 10
    home_phone
  else
    'Invalid HomePhone'
  end

end

# Adds to hash the number of registers at given hour
def store_peak_hour(regdate, peak_hour)
  if peak_hour.key?(DateTime.strptime(regdate, '%m/%d/%Y %H:%M').hour)
    peak_hour[DateTime.strptime(regdate, '%m/%d/%Y %H:%M').hour] += 1
  else
    peak_hour[DateTime.strptime(regdate, '%m/%d/%Y %H:%M').hour] = 1
  end
end

# Adds to hash the number of registers at given day
def store_peak_day(regdate, peak_day)
  if peak_day.key?(DateTime.strptime(regdate, '%m/%d/%Y %H:%M').wday)
    peak_day[DateTime.strptime(regdate, '%m/%d/%Y %H:%M').wday] += 1
  else
    peak_day[DateTime.strptime(regdate, '%m/%d/%Y %H:%M').wday] = 1
  end
end

# Outputs peak hours
def fetch_hour_target(peak_hour)
  peak_hour.each { |k, v| puts "Peak hour is: #{k} at #{v} registers" if v == peak_hour.values.max }
end

# Outputs peak days
def fetch_day_target(peak_day)
  peak_day.each { |k, v| puts "Peak day is: #{k} at #{v} registers" if v == peak_day.values.max }
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

peak_hour = {}
peak_day = {}
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  home_phone = clean_home_phone(row[:homephone])

  store_peak_hour(row[:regdate], peak_hour)
  store_peak_day(row[:regdate], peak_day)
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

fetch_hour_target(peak_hour)
fetch_day_target(peak_day)
