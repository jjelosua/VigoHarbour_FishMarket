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
  begin
    @dbTables_hash.each_key do |key|
      array = @dbTables_hash[key]
      load_db_array(key,array)
    end
  ensure
    $db.close
  end
end

def load_db_array (table,array)
  @db_dim_hash[array] = {}
  $db.query("SET NAMES utf8")
  results = $db.query "SELECT * FROM #{table}"
  if results.num_rows > 0
    puts "table: #{table} has #{results.num_rows} results"
    results.each do |row|
      id, value = row
      @db_dim_hash[array][value] = Integer(id)
    end
    results.free
  end
end

def removeDuplicateValues()
  @dim_hash.each_key do |key|
    aux = @dim_hash[key].uniq
    @dim_hash[key] = aux
  end
end

def sortValues()
  @dim_hash.each_key do |key|
    aux = @dim_hash[key].sort
    @dim_hash[key] = aux
  end
end

def debugLengths()
  @dim_hash.each_key do |key|
    puts "#{key}: #{@dim_hash[key].length}"
  end
end

def writeOutputFiles()
  @dim_hash.each_key do |key|
    output_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{@filenames_hash[key]}", 'w')
    @dim_hash[key].each{|item| output_file.puts(item)}
    output_file.close
  end
end

LOG_SUBDIR = '../logs'
INPUT_FILES_SUBDIR = '../txt'
DATES_INPUT_FILE = 'dates.csv'
LANDED_FISH_INPUT_FILE = 'lfData.csv'
LANDED_SEAFOOD_INPUT_FILE = 'lsData.csv'
FISH_MARKET_INPUT_FILE = 'fmData.csv'
SHIP_INPUT_FILE = 'sData.csv'
OUTPUT_FILES_SUBDIR = '../updateDim'
FileUtils.makedirs(LOG_SUBDIR)
FileUtils.makedirs(OUTPUT_FILES_SUBDIR)

@filenames_hash = {"array_dates"=>"DIM_DATES_UPDATE.txt",
                  "array_family"=>"DIM_FAMILY_UPDATE.txt",
                  "array_marketType" => "DIM_MARKETTYPE_UPDATE.txt",
                  "array_shipType" => "DIM_SHIPTYPE_UPDATE.txt",
                  "array_species"=>"DIM_SPECIES_UPDATE.txt",
                  "array_units"=>"DIM_UNITS_UPDATE.txt"}
                  
@dbTables_hash = {"DIM_DATES"=>"dbdatesId",
                  "DIM_FAMILY"=>"dbFamilyId",
                  "DIM_MARKETTYPE" => "dbMarketTypeId",
                  "DIM_SHIPTYPE" => "dbShipTypeId",
                  "DIM_SPECIES" => "dbSpeciesId",
                  "DIM_UNITS" => "dbUnitsId"}
                  
@dim_hash = Hash.new {|h,k| h[k] = [] }
@db_dim_hash = Hash.new {|h,k| h[k] = {} }

$log_file = File.open("#{LOG_SUBDIR}/extractDimFiles.log", 'w')
begin
  $db = Mysql.init
  $db.options(Mysql::SET_CHARSET_NAME, 'utf8')
  $db.real_connect('localhost','enrique', '', 'APVigo_FishMarket')
  $db.query("SET NAMES utf8")
rescue Mysql::Error
  $log_file.puts("#We could not connect with the DB")
  exit 1
end
#Load the existing db dimension tables
load_db_dim_arrays()

#process the dates file
CSV.foreach("#{INPUT_FILES_SUBDIR}/#{DATES_INPUT_FILE}", :quote_char => '"', :col_sep =>'|', :row_sep =>:auto) do |row|
    date = row[0]
    if !(@db_dim_hash["dbdatesId"].has_key?(date))
      @dim_hash["array_dates"].push(date)
    end
end
puts "#{INPUT_FILES_SUBDIR}/#{DATES_INPUT_FILE}: processed"
#process the ship file
CSV.foreach("#{INPUT_FILES_SUBDIR}/#{SHIP_INPUT_FILE}", :quote_char => '"', :col_sep =>'|', :row_sep =>:auto) do |row|
    date,shipType,amount,marketType = row
    if !(@db_dim_hash["dbdatesId"].has_key?(date))
      if !(@db_dim_hash["dbShipTypeId"].has_key?(shipType))
        @dim_hash["array_shipType"].push(shipType) if shipType.length>0
      end
      if !(@db_dim_hash["dbMarketTypeId"].has_key?(marketType))
        @dim_hash["array_marketType"].push(marketType)
      end
    end
end
puts "#{INPUT_FILES_SUBDIR}/#{SHIP_INPUT_FILE}: processed"

#process the landed Fish file
CSV.foreach("#{INPUT_FILES_SUBDIR}/#{LANDED_FISH_INPUT_FILE}", :quote_char => '"', :col_sep =>'|', :row_sep =>:auto) do |row|
    date,comp_amount = row
    if !(@db_dim_hash["dbdatesId"].has_key?(date))
      #Process the units of the landed fish file
      vars = comp_amount.split(" ")
      unit = vars[1]
      if !(@db_dim_hash["dbUnitsId"].has_key?(unit))
        @dim_hash["array_units"].push(unit) if unit.length>0
      end
    end
end
puts "#{INPUT_FILES_SUBDIR}/#{LANDED_FISH_INPUT_FILE}: processed"

#process the landed Seafood file
CSV.foreach("#{INPUT_FILES_SUBDIR}/#{LANDED_SEAFOOD_INPUT_FILE}", :quote_char => '"', :col_sep =>'|', :row_sep =>:auto) do |row|
    date,comp_amount = row
    if !(@db_dim_hash["dbdatesId"].has_key?(date))
      #Process the units of the landed fish file
      vars = comp_amount.split(":")
      marketType = vars[0];
      if !(@db_dim_hash["dbMarketTypeId"].has_key?(marketType))
        @dim_hash["array_marketType"].push(marketType)
      end
      aux = vars[1].strip.split(" ")
      unit = aux[1]
      if !(@db_dim_hash["dbUnitsId"].has_key?(unit))
        @dim_hash["array_units"].push(unit) if unit.length>0
      end
    end
end
puts "#{INPUT_FILES_SUBDIR}/#{LANDED_SEAFOOD_INPUT_FILE}: processed"

#process the fish market file
CSV.foreach("#{INPUT_FILES_SUBDIR}/#{FISH_MARKET_INPUT_FILE}", :quote_char => '"', :col_sep =>'|', :row_sep =>:auto) do |row|
    date,specie,family,fDate,iPrice,fPrice,amount,marketType = row
    if !(@db_dim_hash["dbdatesId"].has_key?(date))
      if !(@db_dim_hash["dbSpeciesId"].has_key?(specie))
        @dim_hash["array_species"].push(specie)
      end
      if !(@db_dim_hash["dbFamilyId"].has_key?(family))
        @dim_hash["array_family"].push(family)
      end
      if !(@db_dim_hash["dbMarketTypeId"].has_key?(marketType))
        @dim_hash["array_marketType"].push(marketType)
      end
    end
end
puts "#{INPUT_FILES_SUBDIR}/#{FISH_MARKET_INPUT_FILE}: processed"


removeDuplicateValues()
sortValues()
writeOutputFiles()