require 'csv'
require 'pry'
require 'action_view'
require 'fileutils'

# gen_sas goes first, then sasmap needs to be generated from the header
# after that asproducts, wsproduct, maproducts, can be created
# with amendments to the string types

#lib/tasks/import.rake
task :csv_model_import, [ :filename, :model ] => [ :environment ] do |task,args|

    asdata = CSV.read(args[:filename], encoding:"cp1252")
    keys = asdata.shift

    if args[:model] == 'Asproduct'
      keys[keys.index "id"] = "sku"
      puts "\nheading name 'id' changed to 'sku'\n"
    else
        if keys.index "id"
            # TODO rename primary_key_field so that id can be used
            # for the time being I'm changing 'id' to 'sku' in the 3dcart table
            puts "you have a field named id, but sql needs that"
            break
        end
    end
    if args[:model] == 'Sasproduct'
        keys = Sasmap.attribute_names[1..-3]
    end

    asdata.each do |values|
        params = {}
        keys.each_with_index do |key,i|
            params[key] = values[i] == nil ? "" : values[i]
        end
        Module.const_get(args[:model]).create(params)
    end
end

task :show_off => :environment do
    Sasproduct.where(:storeid => "1").each { |p| puts p.name }
    Sasproduct.where(:storeid => "2").each { |p| puts p.name }
    puts "How many with :StoreID 1?"
    Sasproduct.where(:storeid => "1").count
    puts "How many with :StoreID 2?"
    Sasproduct.where(:storeid => [1]).count
    puts "How many with either?"
    Sasproduct.where(:storeid => [1..2]).count
end

task :delete_all_storeid_2 => :environment do
    Sasproduct.delete(Sasproduct.where(:storeid => "2").map { |p| p.id })
    # or you can do it this way
    Sasproduct.where(:storeid => "2").delete_all
end

task :sasmap_3dcart, [ :prefix ] => [ :environment ] do |task,args|
    # ok, didn't have as much fun with the database as I would have liked so instead...
    # we're gonna grab the sas header (post modification) from the backup file
    # then parse the JSON to use as keys for the sasmap object

    sash = JSON.parse File.new("./data/sashead.json").readline

    mappings = Sasmap.first

    pre = args[:prefix]
    premap = {
        :WS => ["1","http://www.wrightstuff.biz"],
        :AS => ["2", "http://www.arthritissupplies.com"],
        :CG => ["3", "http://www.caregiverproducts.com"], 
        :MA => ["4", "http://www.mobility-aids.com"]
    }
    puts "Using URL: #{premap[pre.to_sym].last} as root"

    if File.exists? "./data/#{pre}-exceptions.log"
        FileUtils.rm "./data/#{pre}-exceptions.log"
    end
    outp = "columns:\nnotforsale | stock | sku | name | categories\n"
    puts outp.encode!("cp1252")
    File.open("./data/#{pre}-exceptions.log", "a+:cp1252") { |f| f << "#{outp}\n" }


    include ActionView::Helpers::SanitizeHelper

    # start with the mappings
    products = Module.const_get("#{pre.capitalize}product").all
    products.each do |pdata|

      # first weed out the products with no stock - or not for sale
      skipit = false
      if pdata.notforsale == "1" || pdata.stock == "0"
          a = [:notforsale, :stock, :sku, :name, :categories].map { |x| pdata[x] }
          outp = a.join " | "
          if pdata.stock == "0"
              if outp =~ /discontinued/i
                  skipit = true
              else
                  outp += " <==== ### Not excluded from feed. ###"
              end
          end
          if pdata.notforsale == "1"
              skipit = true
          end
          puts outp.encode!("cp1252")
          File.open("./data/#{pre}-exceptions.log", "a+:cp1252") { |f| f << "#{outp}\n" }
          if skipit
              next
          end
      end
      # Ok, lets break it down
      begin
        cats = pdata[:categories].split("@").pop.split("/")
      rescue
        cats = []
      end

      # and build it up again
      params = {}
      mappings.attribute_names[1..-3].each_with_index do |key,i|
        if pdata[mappings[key]] == nil
          pdata[mappings[key]] = mappings[key] # mappings[key] contains default if no mapping
        end

        data = pdata[mappings[key]]

        root = premap[pre.to_sym].last

        case key
        when /storeid/i
            data = premap[pre.to_sym].first
        when /status/i
            data = "instock"
        when /description/i
            data = strip_tags(data)
        when /url_to_product/i, /url_to_image/i
            if data.index("/") == 0
                data = root + data
            else
                data = "#{root}/#{data}"
            end
        when /url_to_thumbnail/i
            if data.index("/") == 0
                data = root + "/thumbnail.asp?file=" + data + "&maxx=50&maxy=0"
            else
                data = "#{root}/thumbnail.asp?file=/#{data}&maxx=50&maxy=0"
            end
        when /merchantcategory/i
            data = cats[0]
        when /merchantsubcategory/i
            data = cats[1]
        when /merchantgroup/i
            data = cats[2]
        when /merchantsubgroup/i
            data = cats[3]
        when /QuantityDiscount/i
            data = nil
        end

        if data =~ /<\w+?>/
            puts data + " is invalid, possibly\n"
        end
        #puts "#{i}\t|\t#{key}\t|\t#{data}"

        params[key] = data
      end
      Sasproduct.create(params);
    end

    # visually inspect the thumbnails
    Sasproduct.select("URL_to_thumbnail_image").where("StoreID = 2").map { |sp| sp.URL_to_thumbnail_image }

end

task :export_sasfeed, [:prefix] => [:environment] do |task,args|
    header = JSON.parse File.read("./data/sasspec.json")

    prefs = {WS:'1', AS:'2', CG:'3', MA:'4'}
    pdata = Sasproduct.where(:StoreID => prefs[args[:prefix].to_sym])
    file = "./data/#{args[:prefix]}-SAS-products-export.csv"

    fields = pdata.attribute_names[1..-3]
    puts "selected attributes: #{fields}"

    CSV.open(file, "wb:cp1252") do |csv|
        csv << header
        pdata.select(fields).each do |record|
            csv << record.attributes.values
        end
    end
end

task :outputerrors => :environment do
    header = JSON.parse File.read("./data/sasspec.json")

    pdata = Sasproduct.where('StoreID NOT IN ( "1", "2", "4" )')
    csv = CSV.open("oopsSet.csv", "wb:cp1252")
    pdata.select(Sasproduct.attribute_names[1..-3]).each { |r| csv << r.attributes.values }
    csv.close

end

task :totals => :environment do
    puts "WS SAS-feed product data records: #{Sasproduct.where(StoreID:'1').count}"
    puts "AS SAS-feed product data records: #{Sasproduct.where(StoreID:'2').count}"
    puts "CG SAS-feed product data records: #{Sasproduct.where(StoreID:'3').count}"
    puts "MA SAS-feed product data records: #{Sasproduct.where(StoreID:'4').count}"
    puts "total: #{Sasproduct.count}"
end

task :del, [ :target ] => [ :environment ] do |task,args|
    puts Sasproduct.where(StoreID:args[:target]).delete_all
end

task :gen_scaffold_args, [ :filename, :model ] => [ :environment ] do |task,args|

  asdata = CSV.read(args[:filename], encoding:"cp1252")
  header = asdata.first

  output = ""
  header.each { |x| output += x+":string " };

  output = "rails generate scaffold #{args[:model]} #{output}"

  outname = "./data/" + args[:model] + "_genscaff.sh"
  File.new(outname, "w").write output

  # if you have a table heading named ID, that will not do.
  # also if you have things with duplicate names, no good at all
  if output =~ /id:string/
    puts "Whoooooa! Id is not ok for a field name!\n"
  end
end

task :gen_sas => :environment do

  sashead = CSV.parse(File.new("./data/shareasale.csv").readline, encoding:"cp1252").shift
  # save a copy of original column names
  sasspec = []
  sashead.each { |val| sasspec.push val }

  sasspec = sasspec.to_json
  Stuff.create(name:"sasspec", data:sasspec)
  File.new("./data/sasspec.json", "w").write sasspec

  # then modify whitespace
  sashead.each_with_index { |val,i| sashead[i] = val.gsub(/ /,"_") }

  # save the header keys
  count = 0
  sashead.map! do |shd|
    if shd == "ReservedForFutureUse"
        shd = "#{shd}#{count+=1}"
    else
        shd
    end
  end
  Stuff.create(name:"sashead", data:sashead.to_json)
  File.new("./data/sashead.json","w").write sashead.to_json

  first, *rest = *sashead
  outStr = "#{first}:string"
  rest.each { |shd| outStr += " #{shd}:string" }

  outStr = "rails generate scaffold Sasmap #{outStr}"
  File.new("./data/Sasmap_genscaf.sh", "w").write outStr

  # adjust the field types for larger strings
  outStr = "#{first}:string"
  rest.each do |shd|
    case shd
    when "Description", "SearchTerms"
      type = ":text"
    else
      type = ":string"
    end
    outStr += " #{shd}#{type}"
  end

  outStr = "rails generate scaffold Sasproduct #{outStr}"
  File.new("./data/Sasproduct_genscaf.sh", "w").write outStr

  puts "\nDon't forget to double check your string limits.\n"
  puts "However, Sasmap_genscaf.sh should be all string types\n"
  puts "and Sasproduct_genscaf.sh should have 2 fields altered for text.\n"
end

