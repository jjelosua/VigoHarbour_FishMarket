# encoding: utf-8
require 'fileutils'
require 'open-uri'
require 'nokogiri'

BASE_LIST_URL = 'http://www.apvigo.com/control.php?sph=o_lsteventos_fca='
BASE_LIST_URL_SUFFIX = '%25%25a_iap=1351%25%25a_lsteventos_vrp=0'
LOG_SUBDIR = '../logs'
OUTPUT_FILES_SUBDIR = '../html'
FileUtils.makedirs(LOG_SUBDIR)
FileUtils.makedirs(OUTPUT_FILES_SUBDIR)

$log_file = File.open("#{LOG_SUBDIR}/scrapeFishMarketDates.log", 'w')

for year in 2012..2012
  puts "processing year: #{year}"
  for month in 10..12
    puts "processing month: #{month}"
    for day in 1..31
      fday = "%02d" % (day)
      fmonth = "%02d" % (month)
      date = "#{fday}/#{fmonth}/#{year}"
      key = "#{year}#{fmonth}#{fday}"
      #puts "#{BASE_LIST_URL}#{date}#{BASE_LIST_URL_SUFFIX}"
      page=Nokogiri::HTML(open("#{BASE_LIST_URL}#{date}#{BASE_LIST_URL_SUFFIX}"))
      hasData = page.css('td.dcal_activo_ce a, td.dcal_activo_se a, span#TXT_LISTADOTOTALESLONJA')
      if hasData.length > 0
        doc = open("#{BASE_LIST_URL}#{date}#{BASE_LIST_URL_SUFFIX}")
        # create a new file into to which we copy the webpage contents
        # and then write the contents of the downloaded page (with the readlines method) to this
        # new file on our hard drive
        output_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{key}_fishMarket.html", 'w')
        doc.readlines.each do |line|
          output_file.write(line.gsub!(/\r\n?/, "\n"))
        end
        puts "#{key}: Copied page"
      else
        $log_file.puts("#There is no data for: #{key}")
      end
      #wait 2 seconds before getting the next page, to not overburden the website.
      sleep 2
    end
  end
end