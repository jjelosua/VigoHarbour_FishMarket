# encoding: utf-8
require 'fileutils'
require 'csv'
require 'mysql'

#Patch to make mysql 2.8 utf8 friendly
class Mysql::Result
  def encode(value, encoding = "utf-8")
    String === value ? value.force_encoding(encoding) : value
  end
  
  def each_utf8(&block)
    each_orig do |row|
      yield row.map {|col| encode(col) }
    end
  end
  alias each_orig each
  alias each each_utf8

  def each_hash_utf8(&block)
    each_hash_orig do |row|
      row.each {|k, v| row[k] = encode(v) }
      yield(row)
    end
  end
  alias each_hash_orig each_hash
  alias each_hash each_hash_utf8
end

def load_db_dim_arrays()
  @dbTables_hash.each_key do |key|
    array = @dbTables_hash[key]
    load_db_array(key,array)
  end
end

def load_db_array (table,array)
  @db_dim_hash[array] = {}
  $db.query("SET NAMES utf8")
  results = $db.query "SELECT * FROM #{table}"
  if results.num_rows > 0
    results.each do |row|
      id, value = row
      @db_dim_hash[array][value] = Integer(id)
    end
    results.free
  end
end

def formatOutputValue(str,float)
  if (float)
    val = ("--".eql? str)? "0" : str
    intVal = val.gsub(/\./,"")
    oVal = intVal.gsub(/,/,".")
    return oVal
  else
    return str
  end
end

LOG_SUBDIR = '../logs'
INPUT_FILES_SUBDIR = '../txt'
DATES_INPUT_FILE = 'dates.csv'
LANDED_FISH_INPUT_FILE = 'lfData.csv'
LANDED_SEAFOOD_INPUT_FILE = 'lsData.csv'
FISH_MARKET_INPUT_FILE = 'fmData.csv'
SHIP_INPUT_FILE = 'sData.csv'
VFISH_OUTPUT_FILE = 'DAT_VOL_FISH_UPDATE.txt'
VSEAFOOD_OUTPUT_FILE = 'DAT_VOL_SEAFOOD_UPDATE.txt'
SHIPS_OUTPUT_FILE = 'DAT_SHIPS_UPDATE.txt'
AUCTION_OUTPUT_FILE = 'DAT_AUCTION_UPDATE.txt'
OUTPUT_FILES_SUBDIR = '../updateData'
FileUtils.makedirs(LOG_SUBDIR)
FileUtils.makedirs(OUTPUT_FILES_SUBDIR)
                  
@dbTables_hash = {"DIM_DATES"=>"dbdatesId",
                  "DIM_FAMILY"=>"dbFamilyId",
                  "DIM_MARKETTYPE" => "dbMarketTypeId",
                  "DIM_SHIPTYPE" => "dbShipTypeId",
                  "DIM_SPECIES" => "dbSpeciesId",
                  "DIM_UNITS" => "dbUnitsId"}
                  
@db_dim_hash = Hash.new {|h,k| h[k] = {} }

$log_file = File.open("#{LOG_SUBDIR}/extractDataFiles.log", 'w')

#DB connection
begin
  $db = Mysql.init
  $db.options(Mysql::SET_CHARSET_NAME, 'utf8')
  $db.real_connect('localhost','enrique', '', 'APVigo_FishMarket')
  $db.query("SET NAMES utf8")
rescue Mysql::Error
  $log_file.puts("#We could not connect with the DB")
  exit 1
end

begin
  #Load the existing db dimension tables
  load_db_dim_arrays()

  #get the last id on the fish volume data table
  query = "SELECT MAX(date), MAX(id) FROM DAT_VOL_FISH"
  results = $db.query query
  $vFish_max_date = Date.parse("0001-01-01")
  $vFish_max_id = 0
  if results.num_rows > 0
    results.each do |row|
      $vFish_max_date = Date.parse(row[0]) if row[0]
      $vFish_max_id = Integer(row[1]) if row[1]
    end
    results.free
  end
  
  #get the last id on the seafood volume data table
  query = "SELECT MAX(date), MAX(id) FROM DAT_VOL_SEAFOOD"
  results = $db.query query
  $vSeafood_max_date = Date.parse("0001-01-01")
  $vSeafood_max_id = 0
  if results.num_rows > 0
    results.each do |row|
      $vSeafood_max_date = Date.parse(row[0]) if row[0]
      $vSeafood_max_id = Integer(row[1]) if row[1]
    end
    results.free
  end
  
  #get the last id on the ship data table
  query = "SELECT MAX(date), MAX(id) FROM DAT_SHIPS"
  results = $db.query query
  $ship_max_date = Date.parse("0001-01-01")
  $ship_max_id = 0
  if results.num_rows > 0
    results.each do |row|
      $ship_max_date = Date.parse(row[0]) if row[0]
      $ship_max_id = Integer(row[1]) if row[1]
    end
    results.free
  end
  
  #get the last id on the auction data table
  query = "SELECT MAX(date), MAX(id) FROM DAT_AUCTION"
  results = $db.query query
  $auction_max_date = Date.parse("0001-01-01")
  $auction_max_id = 0
  if results.num_rows > 0
    results.each do |row|
      $auction_max_date = Date.parse(row[0]) if row[0]
      $auction_max_id = Integer(row[1]) if row[1]
    end
    results.free
  end
ensure
  $db.close
end

excep=false
#process the landed fish file
output_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{VFISH_OUTPUT_FILE}", 'w')
oId = $vFish_max_id
CSV.foreach("#{INPUT_FILES_SUBDIR}/#{LANDED_FISH_INPUT_FILE}", :quote_char => '"', :col_sep =>'|', :row_sep =>:auto) do |row|
    date,comp_amount = row
    #obtain shipId
    fDate = Date.parse(date)
    idx = @db_dim_hash["dbdatesId"][date]
    if fDate > $vFish_max_date
      #obtain unitId
      vars = comp_amount.split(" ")
      amount = vars[0]
      oAmount = formatOutputValue(amount,true)
      unit = vars[1]
      idx = @db_dim_hash["dbUnitsId"][unit]
      if idx
        oUnit = idx
      else
        $log_file.puts("#We have not found unit: #{unit} in the DB")
        excep = true
      end
      oId += 1
      #write row to output file
      output_file.puts([oId,date,oAmount,oUnit].join("|"))
    else
      $log_file.puts("#We have already processed: #{date} in the DB")
    end
end
output_file.close
puts "#{INPUT_FILES_SUBDIR}/#{LANDED_FISH_INPUT_FILE}: processed"
#If we have detected anomalies we stop the process so we can review the logs and fix the error.
if excep
  exit 1
end

#process the landed seafood file
output_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{VSEAFOOD_OUTPUT_FILE}", 'w')
oId = $vSeafood_max_id
CSV.foreach("#{INPUT_FILES_SUBDIR}/#{LANDED_SEAFOOD_INPUT_FILE}", :quote_char => '"', :col_sep =>'|', :row_sep =>:auto) do |row|
    date,comp_amount = row
    #obtain shipId
    fDate = Date.parse(date)
    idx = @db_dim_hash["dbdatesId"][date]
    if fDate > $vSeafood_max_date
      #obtain unitId
      vars = comp_amount.split(":")
      marketType = vars[0];
      aux = vars[1].strip.split(" ")
      amount = aux[0]
      oAmount =formatOutputValue(amount,true)
      unit = aux[1]
      idx = @db_dim_hash["dbUnitsId"][unit]
      if idx
        oUnit = idx
      else
        $log_file.puts("#We have not found unit: #{unit} in the DB")
        excep = true
      end
      idx = @db_dim_hash["dbMarketTypeId"][marketType]
      if idx
        oMarketType = idx
      else
        $log_file.puts("#We have not found marketType: #{marketType} in the DB")
        excep = true
      end
      oId += 1
      #write row to output file
      output_file.puts([oId,date,oAmount,oUnit,oMarketType].join("|"))
    else
      $log_file.puts("#We have already processed: #{date} in the DB")
    end
end
output_file.close
puts "#{INPUT_FILES_SUBDIR}/#{LANDED_SEAFOOD_INPUT_FILE}: processed"
#If we have detected anomalies we stop the process so we can review the logs and fix the error.
if excep
  exit 1
end

#process the ships file
output_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{SHIPS_OUTPUT_FILE}", 'w')
oId = $ship_max_id
CSV.foreach("#{INPUT_FILES_SUBDIR}/#{SHIP_INPUT_FILE}", :quote_char => '"', :col_sep =>'|', :row_sep =>:auto) do |row|
    date,shipType,oAmount,marketType = row
    #obtain shipId
    fDate = Date.parse(date)
    if fDate > $ship_max_date
      #Obtain marketTypeId
      idx = @db_dim_hash["dbMarketTypeId"][marketType]
      if idx
        oMarketType = idx
      else
        $log_file.puts("#We have not found marketType: #{marketType} in the DB")
        excep = true
      end
      #Obtain shipTypeId
      idx = @db_dim_hash["dbShipTypeId"][shipType]
      if idx
        oShipType = idx
      else
        $log_file.puts("#We have not found marketType: #{marketType} in the DB")
        excep = true
      end
      oId += 1
      #write row to output file
      output_file.puts([oId,date,oShipType,oAmount,oMarketType].join("|"))
    else
      $log_file.puts("#We have already processed: #{date} in the DB")
    end
end
output_file.close
puts "#{INPUT_FILES_SUBDIR}/#{SHIP_INPUT_FILE}: processed"
#If we have detected anomalies we stop the process so we can review the logs and fix the error.
if excep
  exit 1
end

#process the auction file
output_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{AUCTION_OUTPUT_FILE}", 'w')
oId = $auction_max_id
CSV.foreach("#{INPUT_FILES_SUBDIR}/#{FISH_MARKET_INPUT_FILE}", :quote_char => '"', :col_sep =>'|', :row_sep =>:auto) do |row|
    date,specie,family,fDate,iPrice,fPrice,amount,marketType = row
    fDate = Date.parse(date)
    if fDate > $auction_max_date
      #Format values for output
      oIPrice = formatOutputValue(iPrice,true)
      oFPrice = formatOutputValue(fPrice,true)
      oAmount = formatOutputValue(amount,true)
      #Obtain specieId
      idx = @db_dim_hash["dbSpeciesId"][specie]
      if idx
        oSpecieId = idx
      else
        $log_file.puts("#We have not found specie: #{specie} in the DB")
        excep = true
      end
      #Obtain familyId
      idx = @db_dim_hash["dbFamilyId"][family]
      if idx
        oFamilyId = idx
      else
        $log_file.puts("#We have not found family: #{family} in the DB")
        excep = true
      end
      #Obtain marketTypeId
      idx = @db_dim_hash["dbMarketTypeId"][marketType]
      if idx
        oMarketTypeId = idx
      else
        $log_file.puts("#We have not found marketType: #{marketType} in the DB")
        excep = true
      end
      oId +=1
      #write row to output file
      output_file.puts([oId,date,oSpecieId,oFamilyId,oIPrice,oFPrice,oAmount,1,oMarketTypeId].join("|"))
    else
      $log_file.puts("#We have already processed: #{date} in the DB")
    end
end
output_file.close
puts "#{INPUT_FILES_SUBDIR}/#{FISH_MARKET_INPUT_FILE}: processed"
