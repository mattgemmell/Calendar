#!/usr/bin/ruby


# Calendar
version = "1.0.0" # 2016-02-10
#
# This script outputs a monthly calendar.
# It's very configurable, and can produce CSS-ready HTML output, as well
# as the more conventional monospaced calendar for the command-line.
#
# Made by Matt Gemmell - mattgemmell.com - @mattgemmell
#
github_url = "http://github.com/mattgemmell/Calendar"
#
# Requirements: just Ruby itself, and its standard library.
#
# How to use:
#	• Run the script on the command line for this month's calendar.
#	• Use the -h flag to see a list of available options.


# Configuration defaults; can be overridden on command line and/or conf file.
$startDayOfWeek = 0 # Sunday is 0. Max value is 6, for Saturday.
$numDaysInWeek = 7 # might want to show only weekdays etc


# == Everything below can be overridden in the configuration file.


# Output formatting
$space = " " # should be (at most) one character; will be trimmed to one char
$newline = "\n" # should usually contain at least "\n"
$weekdayHeadingNameLength = 3
$monthHeadingFormatString = "%B %Y" # Date.strftime
$shortenMonthHeadingToFit = true # try shorter formats if necessary to fit

# Layout (spaces horizontally, and lines vertically)
$calendarPadding = {top: 1, bottom: 1, left: 1, right: 1, between: 1} # around entire calendar; "between" is between successive monthly calendars if showing multiple
$calendarHeadingPadding = {top: 1, bottom: 1} # vertical padding above and below the row of weekday headings
$cellSpacing = {horizontal: 1, vertical: 1} # between cells only, not at edges

# Content wrapping
$wrapCurrent = {before_day: "\033[7m", after_day: "\033[0;1m", before_week: "\033[1m", after_week: "\033[0m", before_month: "", after_month: ""}
$currentConditionalMarker = {before: "CURRENT_BEFORE", after: "CURRENT_AFTER"}
=begin
Use the two "currentConditionalMarker" entries in the following "wrap…" hashes.
When the calendar is being generated, in each case the markers will be replaced
with the corresponding "wrapCurrent" entry, iff the day/week/month corresponds 
to the current date. This allows easy styling of today, this week, and this month.

e.g. with the default values for wrapCurrent and currentConditionalMarker:
	wrapCalendar = {before: "<div class='monthCURRENT_BEFORE'>", after: "</div>"}
will yield:
	<div class='month current'>…</div>
for the current month, and:
	<div class='month'>…</div>
for any other months.

e.g. with these values instead:
	wrapCurrent = {before_day: "[", after_day: "]"}
	$wrapDay = {before: "CURRENT_BEFORE", after: "CURRENT_AFTER"}
will yield something like:
	1 2 [3] 4 5
if today is the 3rd day of the requested calendar month.
=end
$wrapOutput = {before: "", after: ""} # around entire output
$wrapCalendar = {before: "CURRENT_BEFORE", after: "CURRENT_AFTER"} # around each monthly calendar
$wrapMonthHeading = {before: "", after: ""} # around calendar month/year heading
$wrapDateGrid = {before: "", after: ""} # includes weekday headings
$wrapWeekdayHeadingsRow = {before: "", after: ""} # around entire weekday heading row
$wrapWeekdayHeading = {before: "", after: ""} # around each weekday heading cell
$wrapDaysGrid = {before: "", after: ""} # not including weekday headings
$wrapDaysRow = {before: "CURRENT_BEFORE", after: "CURRENT_AFTER"} # around each entire row of days
$wrapDay = {before: "CURRENT_BEFORE", after: "CURRENT_AFTER"} # around each individual day cell


require 'date'


def days_in_month(date = DateTime.now)
	# Return day-number of last day in month.
	Date.new(date.year, date.month, -1).day
end

def cellCharacterWidth
	return [2, $weekdayHeadingNameLength].max
end

def calendarCharacterWidth
	return (cellCharacterWidth() * $numDaysInWeek) + 
			($cellSpacing[:horizontal] * ($numDaysInWeek - 1))
end

def month_calendar(month = nil, year = nil)
	firstOfMonthDate = nil
	if month == nil and year == nil
		today = DateTime.now
		month = today.month
		year = today.year
	elsif month == nil
		month = 1
	elsif year == nil
		year = DateTime.now.year
	end
	
	if year < 0
		year = 0
	end
	if month < 1
		month = 1
	elsif month > 12
		month = 12
	end
	
	firstOfMonthDate = DateTime.new(year, month, 1)
	todayDate = DateTime.now
	monthIsCurrent = (todayDate.month == month and todayDate.year == year)
	output = ""
	
	# Sanitise some values
	if $startDayOfWeek < 0
		$startDayOfWeek = $startDayOfWeek + 7
	elsif $startDayOfWeek > 6
		$startDayOfWeek = $startDayOfWeek - 7
	end
	
	if $space.length > 1
		$space = $space.slice(0, 1)
	end
	
	if $numDaysInWeek < 1
		$numDaysInWeek = 1
	elsif $numDaysInWeek > 7
		$numDaysInWeek = 7
	end
	
	# Calculate character-widths, not including calendar's overall padding.
	cellCharWidth = cellCharacterWidth()
	calendarCharWidth = calendarCharacterWidth()
	
	# Handle start-of-calendar wrapping.
	replacement = (monthIsCurrent ? $wrapCurrent[:before_month] : "")
	output = "#{output}#{$wrapCalendar[:before].gsub($currentConditionalMarker[:before], replacement)}"
	
	# Output padding before calendar
	for i in 1..$calendarPadding[:top]
		$calendarPadding[:left].times do output = "#{output}#{$space}" end
		calendarCharWidth.times do output = "#{output}#{$space}" end
		$calendarPadding[:right].times do output = "#{output}#{$space}" end
		output = "#{output}#{$newline}"
	end
	
	# Calendar month heading.
	if $monthHeadingFormatString.length > 0
		monthHeading = firstOfMonthDate.strftime(format = $monthHeadingFormatString)
		$calendarPadding[:left].times do output = "#{output}#{$space}" end
		output = "#{output}#{$wrapMonthHeading[:before]}"
		
		numLeadingSpaces = (calendarCharWidth - monthHeading.length) / 2
		if numLeadingSpaces >= 0
			numLeadingSpaces.times do output = "#{output}#{$space}" end
			output = "#{output}#{monthHeading}"
			remainingSpaces = calendarCharWidth - monthHeading.length - numLeadingSpaces
			remainingSpaces.times do output = "#{output}#{$space}" end
		else
			if $shortenMonthHeadingToFit
				# Try some shorter variants of the heading.
				shorterHeadingFormats = Array["%b %Y", "%b %y", "%b"]
				shorterHeadingFormats.each do |thisFormat|
					shortMonthHeading = firstOfMonthDate.strftime(thisFormat)
					if shortMonthHeading.length <= calendarCharWidth
						numLeadingSpaces = (calendarCharWidth - shortMonthHeading.length) / 2
						numLeadingSpaces.times do output = "#{output}#{$space}" end
						output = "#{output}#{shortMonthHeading}"
						remainingSpaces = calendarCharWidth - shortMonthHeading.length - numLeadingSpaces
						remainingSpaces.times do output = "#{output}#{$space}" end
						break
					end
				end
			else
				# Abbreviate month heading with an ellipsis.
				numAvailableChars = calendarCharWidth - 1
				numLeadingChars = numAvailableChars.fdiv(2).ceil
				numTrailingChars = numAvailableChars - numLeadingChars
				output = "#{output}#{monthHeading.slice(0, numLeadingChars)}…#{monthHeading.slice(-numTrailingChars, numTrailingChars)}"
			end
		end
		output = "#{output}#{$wrapMonthHeading[:after]}"
		$calendarPadding[:right].times do output = "#{output}#{$space}" end
		output = "#{output}#{$newline}"
	
		# Padding between month heading and weekday headings
		for i in 1..$calendarHeadingPadding[:top]
			$calendarPadding[:left].times do output = "#{output}#{$space}" end
			calendarCharWidth.times do output = "#{output}#{$space}" end
			$calendarPadding[:right].times do output = "#{output}#{$space}" end
			output = "#{output}#{$newline}"
		end
	end
	
	output = "#{output}#{$wrapDateGrid[:before]}"
	
	# Weekday headings
	if $weekdayHeadingNameLength > 0
		validWeekdays = Array.new
		monthHeading = firstOfMonthDate.strftime(format = $monthHeadingFormatString)
		$calendarPadding[:left].times do output = "#{output}#{$space}" end
		output = "#{output}#{$wrapWeekdayHeadingsRow[:before]}"
		
		# Output day headings right-aligned in available cell-width if narrower
		for i in 0..($numDaysInWeek - 1)
			weekdayNum = i + $startDayOfWeek
			if weekdayNum >= 7
				weekdayNum -= 7
			end
			validWeekdays.push(weekdayNum)
			# Weekday heading
			dayName = Date::DAYNAMES[weekdayNum].slice(0, $weekdayHeadingNameLength)
			if dayName.length < cellCharWidth
				numLeadingSpaces = cellCharWidth - dayName.length
				numLeadingSpaces.times do output = "#{output}#{$space}" end
			end
			output = "#{output}#{$wrapWeekdayHeading[:before]}"
			output = "#{output}#{dayName}"
			output = "#{output}#{$wrapWeekdayHeading[:after]}"
			
			if i < ($numDaysInWeek - 1)
				# Intercell horizontal separator
				$cellSpacing[:horizontal].times do output = "#{output}#{$space}" end
			end
		end
		
		output = "#{output}#{$wrapWeekdayHeadingsRow[:after]}"
		$calendarPadding[:right].times do output = "#{output}#{$space}" end
		output = "#{output}#{$newline}"
	
		# Padding between weekday headings and day grid
		for i in 1..$calendarHeadingPadding[:bottom]
			$calendarPadding[:left].times do output = "#{output}#{$space}" end
			calendarCharWidth.times do output = "#{output}#{$space}" end
			$calendarPadding[:right].times do output = "#{output}#{$space}" end
			output = "#{output}#{$newline}"
		end
	end
	
	output = "#{output}#{$wrapDaysGrid[:before]}"
	
	# Day grid rows, each (except last) with vertical cell spacing afterwards
	numDaysInMonth = days_in_month(firstOfMonthDate)
	startingWeekdayOfMonth = firstOfMonthDate.wday
	monthWeekStartOffset = ($startDayOfWeek - (startingWeekdayOfMonth + 7))
	if monthWeekStartOffset < -6
		monthWeekStartOffset = monthWeekStartOffset + 7
	end
	currentDayNum = 1 + monthWeekStartOffset
	numRows = (numDaysInMonth - monthWeekStartOffset).fdiv(7).ceil
	numCells = numRows * $numDaysInWeek
	
	#puts "We're processing day #{firstOfMonthDate.day} of #{numDaysInMonth} in this month."
	#puts "We're starting weeks on a #{Date::DAYNAMES[$startDayOfWeek]} (weekday #{$startDayOfWeek}), and showing #{$numDaysInWeek} days per week."
	#puts "This month started on a \033[1m#{Date::DAYNAMES[startingWeekdayOfMonth]}\033[0m (weekday #{startingWeekdayOfMonth})."
	#puts "Offset of 1st of this month from starting day of week is #{monthWeekStartOffset}."
	#puts "Starting on effective day number #{currentDayNum}."
	#puts "We'll need #{numRows} rows, with a total of #{numCells} cells."
	
	# Adjust starting point if necessary.
	startingCellNum = 1
	if monthWeekStartOffset.abs >= $numDaysInWeek
		startingCellNum = startingCellNum + $numDaysInWeek
	end
	
	lastRowStartEffectiveDay = 0
	for i in startingCellNum..numCells
		# Work out correct currentDayNum (or blank space) to show for this cell.
		
		row = (i / $numDaysInWeek) + 1
		if (i % $numDaysInWeek) == 0
			row = row - 1
		end
		
		col = (i % $numDaysInWeek)
		if col == 0
			col = $numDaysInWeek
		end
		
		currentDayNum = col + monthWeekStartOffset + ((row - 1) * 7)
		effectiveDayNum = currentDayNum
		if col == 1
			lastRowStartEffectiveDay = effectiveDayNum
		end
		if currentDayNum < 1 or currentDayNum > numDaysInMonth
			# This is a blank cell.
			currentDayNum = 0
		end
		
		# Work out if this row/week and/or cell contains today.
		weekIsCurrent = false
		dayIsCurrent = false
		if monthIsCurrent
			if todayDate.day >= lastRowStartEffectiveDay and todayDate.day < lastRowStartEffectiveDay + 7 
				weekIsCurrent = true
				if todayDate.day == effectiveDayNum
					dayIsCurrent = true
				end
			end
		end
		
		# Decide if we need to start a row.
		if col == 1
			$calendarPadding[:left].times do output = "#{output}#{$space}" end
			
			# Handle start-of-row wrapping.
			replacement = (weekIsCurrent ? $wrapCurrent[:before_week] : "")
			output = "#{output}#{$wrapDaysRow[:before].gsub($currentConditionalMarker[:before], replacement)}"
		end
		
		# Output either a blank cell or a day-number.
		cellContent = (currentDayNum == 0 ? "" : "#{currentDayNum}")
		#puts "cell #{i}, row #{row}, col #{col} [#{cellContent}]"
		if cellContent.length < cellCharWidth
			numLeadingSpaces = cellCharWidth - cellContent.length
			numLeadingSpaces.times do output = "#{output}#{$space}" end
		end
		
		# Handle start-of-day wrapping.
		replacement = (dayIsCurrent ? $wrapCurrent[:before_day] : "")
		output = "#{output}#{$wrapDay[:before].gsub($currentConditionalMarker[:before], replacement)}"
		
		# Output cell contents
		output = "#{output}#{cellContent}"
		
		# Handle end-of-day wrapping.
		replacement = (dayIsCurrent ? $wrapCurrent[:after_day] : "")
		output = "#{output}#{$wrapDay[:after].gsub($currentConditionalMarker[:after], replacement)}"
		
		# Output either horizontal cell-spacing or the end of a row.
		if col < $numDaysInWeek
			# Output horizontal cell-spacing
			$cellSpacing[:horizontal].times do output = "#{output}#{$space}" end
		else
			# Handle end-of-row wrapping.
			replacement = (weekIsCurrent ? $wrapCurrent[:after_week] : "")
			output = "#{output}#{$wrapDaysRow[:after].gsub($currentConditionalMarker[:after], replacement)}"
			
			# Output end of row padding and newline
			$calendarPadding[:right].times do output = "#{output}#{$space}" end
			output = "#{output}#{$newline}"
			
			# Decide whether to output vertical cell-spacing before the next row.
			if row < numRows
				# Output vertical cell-spacing
				for i in 1..$cellSpacing[:vertical]
					$calendarPadding[:left].times do output = "#{output}#{$space}" end
					calendarCharWidth.times do output = "#{output}#{$space}" end
					$calendarPadding[:right].times do output = "#{output}#{$space}" end
					output = "#{output}#{$newline}"
				end
			end
		end
	end
	
	output = "#{output}#{$wrapDaysGrid[:after]}"
	output = "#{output}#{$wrapDateGrid[:after]}"
	
	# Output padding after calendar
	for i in 1..$calendarPadding[:bottom]
		$calendarPadding[:left].times do output = "#{output}#{$space}" end
		calendarCharWidth.times do output = "#{output}#{$space}" end
		$calendarPadding[:right].times do output = "#{output}#{$space}" end
		output = "#{output}#{$newline}"
	end
	
	# Handle end-of-calendar wrapping.
	replacement = (monthIsCurrent ? $wrapCurrent[:after_month] : "")
	output = "#{output}#{$wrapCalendar[:after].gsub($currentConditionalMarker[:after], replacement)}"
	
	return output
end

def makeCalendars(months)
	output = ""
	interCalendarPadding = ""
	if months.count > 1
		for i in 1..$calendarPadding[:between]
			$calendarPadding[:left].times do interCalendarPadding = "#{interCalendarPadding}#{$space}" end
			calendarCharacterWidth().times do interCalendarPadding = "#{interCalendarPadding}#{$space}" end
			$calendarPadding[:right].times do interCalendarPadding = "#{interCalendarPadding}#{$space}" end
			interCalendarPadding = "#{interCalendarPadding}#{$newline}"
		end
	end
	
	for i in 0..(months.count - 1)
		thisCalendar = month_calendar(months[i].month, months[i].year)
		output = "#{output}#{thisCalendar}"
		if i < (months.count - 1)
			output = "#{output}#{interCalendarPadding}"
		end
	end
	
	output = "#{$wrapOutput[:before]}#{output}#{$wrapOutput[:after]}"
	
	return output
end


# == End of functions ==


# Pay attention to any config options on the command line
config_file = nil
todayDate = DateTime.now
monthNum = todayDate.month
yearNum = todayDate.year
monthOverridden = false
yearOverridden = false
startingWeekdayOverridden = false
numDaysInWeekOverridden = false
showSurroundingMonths = false

require 'optparse'
parser = OptionParser.new do |opts|
	opts.banner = "Usage: #{$0} [options]"

	opts.on("-m n", "--month", OptionParser::DecimalInteger, "Shows a calendar for given month in current year (1 = January)") do |month|
		monthNum = month
		monthOverridden = true
	end

	opts.on("-y n", "--year", OptionParser::DecimalInteger, "With -m, chooses the year; otherwise shows every month of given year") do |year|
		yearNum = year
		yearOverridden = true
	end

	opts.on("-S", "--show-surrounding", "Also shows months before and after the specified month") do
		showSurroundingMonths = true
	end

	opts.on("-w n", "--starting-weekday", OptionParser::DecimalInteger, "Starts weeks on the given day (0 = Sunday)") do |startingWeekday|
		$startDayOfWeek = startingWeekday
		startingWeekdayOverridden = true
	end

	opts.on("-n n", "--days-per-week", OptionParser::DecimalInteger, "Sets the number of days per week to show") do |numDays|
		$numDaysInWeek = numDays
		numDaysInWeekOverridden = true
	end

	opts.on("-c file", "--config=file",
              "Use file as the configuration file") do |config|
		config_file = config
	end

	opts.on("-v", "--version", "Shows the version") do
		puts <<END
#{$0} version #{version} ~ #{github_url}
END
		exit
	end
end
parser.parse!(ARGV)


# Load external config file
if config_file != nil
	require "yaml"
	config = {}
	if File.exist?(config_file)
		config = YAML::load_file(config_file)
	else
		puts "Couldn't find the config file \"#{config_file}\". Using default settings."
	end

	# Allow config file to override internal values
	if (config["startDayOfWeek"] and !startingWeekdayOverridden)
		$startDayOfWeek = config["startDayOfWeek"]
	end
	if (config["numDaysInWeek"] and !numDaysInWeekOverridden)
		$numDaysInWeek = config["numDaysInWeek"]
	end
		if (config["space"])
		$space = config["space"]
	end
	if (config["newline"])
		$newline = config["newline"]
	end
	if (config["weekdayHeadingNameLength"])
		$weekdayHeadingNameLength = config["weekdayHeadingNameLength"]
	end
	if (config["monthHeadingFormatString"])
		$monthHeadingFormatString = config["monthHeadingFormatString"]
	end
	if (config["shortenMonthHeadingToFit"])
		$shortenMonthHeadingToFit = config["shortenMonthHeadingToFit"]
	end
	if (config["calendarPadding"])
		$calendarPadding = config["calendarPadding"]
	end
	if (config["calendarHeadingPadding"])
		$calendarHeadingPadding = config["calendarHeadingPadding"]
	end
	if (config["cellSpacing"])
		$cellSpacing = config["cellSpacing"]
	end
	if (config["wrapCurrent"])
		$wrapCurrent = config["wrapCurrent"]
	end
	if (config["currentConditionalMarker"])
		$currentConditionalMarker = config["currentConditionalMarker"]
	end
	if (config["wrapOutput"])
		$wrapOutput = config["wrapOutput"]
	end
	if (config["wrapCalendar"])
		$wrapCalendar = config["wrapCalendar"]
	end
	if (config["wrapMonthHeading"])
		$wrapMonthHeading = config["wrapMonthHeading"]
	end
	if (config["wrapDateGrid"])
		$wrapDateGrid = config["wrapDateGrid"]
	end
	if (config["wrapWeekdayHeadingsRow"])
		$wrapWeekdayHeadingsRow = config["wrapWeekdayHeadingsRow"]
	end
	if (config["wrapWeekdayHeading"])
		$wrapWeekdayHeading = config["wrapWeekdayHeading"]
	end
	if (config["wrapDaysGrid"])
		$wrapDaysGrid = config["wrapDaysGrid"]
	end
	if (config["wrapDaysRow"])
		$wrapDaysRow = config["wrapDaysRow"]
	end
	if (config["wrapDay"])
		$wrapDay = config["wrapDay"]
	end
end


# Create appropriate calendar(s).
monthDates = Array.new

if yearOverridden and !monthOverridden
	# Show full year of monthly calendars.
	for i in 1..12
		monthDates.push(DateTime.new(yearNum, i, 1))
	end
else
	# Show a single monthly calendar.
	theMonth = DateTime.new(yearNum, monthNum, 1)
	monthDates.push(theMonth)
end

# Deal with 'surrounding' flag.
if showSurroundingMonths
	monthDates.unshift(monthDates.first.prev_month)
	monthDates.push(monthDates.last.next_month)
end

# Obtain and echo output.
output = makeCalendars(monthDates)
print output
