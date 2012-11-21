# encoding: utf-8
require 'open-uri'
require 'fileutils'
require 'nokogiri'
require 'csv'

class String
  # a helper function to turn all tabs, carriage returns, multiple spaces or nbsp into a regular space
  def astrip
    self.gsub(/([\s|\n|\t]){1,}/, ' ').strip
  end
end

LOG_SUBDIR = '../logs'
INPUT_FILES_SUBDIR = '../html'
OUTPUT_FILES_SUBDIR = '../csv'
DATES_FILE_NAME = 'dates.csv'
LAND_FISH_DATA_FILE_NAME = 'lfData.csv'
LAND_SEAFOOD_DATA_FILE_NAME = 'lsData.csv'
FISH_MARKET_DATA_FILE_NAME = 'fmData.csv'
SHIP_DATA_FILE_NAME = 'sData.csv'
FileUtils.makedirs(LOG_SUBDIR)
FileUtils.makedirs(OUTPUT_FILES_SUBDIR)

$log_file = File.open("#{LOG_SUBDIR}/processFishMarketInfo.log", 'w')
dates_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{DATES_FILE_NAME}", 'w')
lfData_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{LAND_FISH_DATA_FILE_NAME}", 'w')
lsData_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{LAND_SEAFOOD_DATA_FILE_NAME}", 'w')
fmData_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{FISH_MARKET_DATA_FILE_NAME}", 'w')
sData_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{SHIP_DATA_FILE_NAME}", 'w')

count = 0
quote = "\""
Dir.entries("#{INPUT_FILES_SUBDIR}").select{|f| f.match(/.*_fishMarket.html/)}.each do |doc|
  data = false
  puts "Reading #{doc}"
  vars=doc.split('_')
  date="#{vars[0][0,4]}-#{vars[0][4,2]}-#{vars[0][6,2]}"
  page = Nokogiri::HTML(open("#{INPUT_FILES_SUBDIR}/#{doc}"))
  
  #Landed Fish Data
  lfData = page.css('span#TXT_LISTADOTOTALESLONJA')
  process_lfData = lfData.length > 0 ? true : false
  if process_lfData
    if lfData.text =~ /(\d){1,4},(\d){2} Tm./
      data = true
      lfData_file.puts("\""+[date,$&].map{|t| t.astrip}.join("\"|\"")+"\"")
    else
      $log_file.puts("LANDED_FISH_INFO: No landed fish data found on #{INPUT_FILES_SUBDIR}/#{doc}")
    end
  end
  
  #Landed Seafood Data
  lsData = page.css('span.h2')
  process_lsData =  lsData.length > 0 ? true : false
  if process_lsData
    lsData.each do |item|
      if item.text =~ /(\d){1,3},(\d){2}/
        data = true
        lsData_file.puts("\""+[date,item.text].map{|t| t.astrip}.join("\"|\"")+"\"")
      else
        $log_file.puts("LANDED_SEAFOOD_INFO: No landed seafood data found on #{INPUT_FILES_SUBDIR}/#{doc}")
      end
    end
  end
  
  #FishMarket and ship Data
  rows = page.css('tr')
  rows.each do |row|
    cells = row.css('td')
    #FishMarket Data
    if cells.length == 7
      if cells[2].text =~ /(\d\d)\/(\d\d)\/(\d\d\d\d)/
        data = true
        cSpecies,cfamily,cDate,cInitialPrice,cFinalPrice,cAmount,cFishMarket = cells[0..6].map{|c| c.text.astrip}
        fmData_file.puts("\""+[date,cSpecies,cfamily,cDate,cInitialPrice,cFinalPrice,cAmount,cFishMarket].map{|t| t.astrip}.join("\"|\"")+"\"")
      else
        #$log_file.puts("FISH_AUCTION_INFO: Found a 7 cells row but did not match fish auction info #{INPUT_FILES_SUBDIR}/#{doc}")
      end
    elsif cells.length == 3
      if cells[2].text =~ /.*LONJA.*/
        data = true
        cType,cTotal,cFishMarket = cells[0..2].map{|c| c.text.astrip}
        sData_file.puts("\""+[date,cType,cTotal,cFishMarket].map{|t| t.astrip}.join("\"|\"")+"\"")
      else
        #$log_file.puts("SHIP_CARGO_INFO: Found a 3 cells row but did not match ship cargo info #{INPUT_FILES_SUBDIR}/#{doc}")
      end
    end
  end
  if (data)
    dates_file.puts(date)
  end
  count += 1
end
puts "We have processed the information of #{count} dates"
lfData_file.close
lsData_file.close
fmData_file.close
sData_file.close