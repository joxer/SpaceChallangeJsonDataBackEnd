require 'mechanize'
require 'uri'
require 'net/http'
require 'csv'
require 'json'
#require 'sinatra'

# DATA ORA
# NOME TARGET
# 


module DownloadData

  class NasaObject
    attr_reader :startdate,:enddate,:target,:ra,:dec
    def initialize(startdate,enddate,target,ra,dec)
      @startdate,@enddate,@target,@ra,@dec = startdate,enddate,target,ra,dec
    end

    def to_json
      JSON.pretty_generate({@startdate,@enddate,@target,@ra,@dec})
    end
  end

  class Swift

    @domain = "https://www.swift.psu.edu"

    def initialize

    end

    def self.download_data(startdate)
      mech = Mechanize.new{|agent| agent.user_agent_alias = "Mac Safari"}
      
      data = mech.get("https://www.swift.psu.edu/operations/obsSchedule.php?d=#{startdate}&a=0")
      objects = []
      data.search("tr").each do |tr|
        
        if tr.attributes['class'] != nil && tr.attributes['class'].value =~ /(saa\d+|norm\d+)/
          begin
            startdate = tr.children[1].children[0].text
            enddate =  tr.children[3].children[0].text
            targetid = tr.children[5].children[1].children[0].text
            seg =  tr.children[9].children[0].text
            targetname =  tr.children[11].children[0].text
            ra = tr.children[13].children[0].text
            dec =  tr.children[15].children[0].text
            roll = tr.children[17].children[0].text
            objects << NasaObject(startdate,enddate,targetname,ra,dec)
          rescue
            next
          end
        end
      end
      return objects
    end
  end

  class Integral
    
    @domain = "http://integral.esac.esa.int/isocweb/"

    def initialize

    end

    def self.download_data(startdate,enddate)
      
      mech = Mechanize.new{|agent| agent.user_agent_alias = "Mac Safari"}
      
      data = mech.get("http://integral.esac.esa.int/isocweb/schedule.html?selectMode=date&action=schedule&startDate=#{startdate}&endDate=#{enddate}")
      link = data.link_with(:text => "here").href
      uri = URI(@domain+link)

      data = []

      CSV.parse(Net::HTTP.get(uri)) do |row|
        data << row
      end

      JSON.pretty_generate(data)

    end
  end
end

if $0 == __FILE__
#  data = DownloadData::Integral.download_data("2012-05-19","2012-06-20")
data = DownloadData::Swift.download_data("2013-04-20")
end

=begin
get '/' do

  startdate = params[:start]
  enddate = params[:end]
  
  DownloadData::Integral.download_data(startdate,enddate)
  
end
=end
