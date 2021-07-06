require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'
require 'pry'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
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
    puts form_letter
  end
end

def clean_phone_number(phone)
  phone = phone.tr('-+().E ', '')
  
  if (phone.length < 10) || ((phone.length == 11) && (phone[0] != '1')) || phone.length > 11
    puts "Bad phone number!"
  elsif (phone.length == 11) && (phone[0] == '1')
    phone[0] = ''
    puts phone
  elsif phone.length == 10
    puts phone
  end
end
puts 'EventManager initialized.'

def set_registration_time_format
  reg_time = Time.new
  reg_time.strftime("%m/%d/%Y %k:%M")
end

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

reg_times = []
best_days_array = []

contents.each do |row|
  phone = row[:homephone]

  set_registration_time_format
  reg_time = row[:regdate]
  
  reg_days_of_the_week = Date.new
  reg_days_of_the_week.strftime("%m")

  reg_days_of_the_week = row[:regdate]
  best_day = DateTime.strptime(reg_days_of_the_week, "%m/%d/%y %H:%M")
  best_day_integer = best_day.wday
  best_days_array.concat(["#{best_day_integer}"])
  
  reg_times.concat(["#{reg_time}"])
end


peak_hours = reg_times.map { |reg_time| reg_time[/\d+(?=:)/] }.tally
peak_registrants = peak_hours.max_by(&:last).last
peak_hours = peak_hours.select { |_hour,registrants| registrants == peak_registrants }.keys
puts "Peak hours in military time: #{peak_hours.join(', ')}"

puts "Days of the week by most to least people registered (0-6, Sunday is 0):#{best_days_array.tally}"

=begin
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end
=end
