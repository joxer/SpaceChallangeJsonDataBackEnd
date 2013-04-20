class JsonController < ApplicationController
  require 'csv'
  
  before_filter :control_params
  def swift

    params[:startdate] = params[:startdate].split("-").reverse.join("-")
    p params
    if (@version = NasaVersion.find("swift"+params[:startdate])) == nil || (DateTime.now - @version.date) > 3600
      
#      p Time.now - @version.date
      data = DownloadData::Swift.download_data(params[:startdate])
      @version = NasaVersion.new#(:version => "swift"+params[:startdate], :content => data, :date => Time.now)
      @version._id = "swift"+params[:startdate]
      @version.content = data
      @version.date = Time.now
      @version.save
    end
    render :json => @version.content
  end

  def integral
    
    if (@version = NasaVersion.find("integral"+params[:startdate]+params[:enddate])) == nil || (DateTime.now - @version.date) > 3600
      
#      p Time.now - @version.date
      data = DownloadData::Integral.download_data(params[:startdate],params[:enddate])
      @version = NasaVersion.new#(:version => "swift"+params[:startdate], :content => data, :date => Time.now)
      @version._id = "integral"+params[:startdate]+params[:enddate]
      @version.content = data
      @version.date = Time.now
      @version.save
    end
    render :json => @version.content


#    data = DownloadData::Integral.download_data(params[:startdate],params[:enddate])
 #   render :json => data
  end

  def nustar
    if (@version = NasaVersion.find("nustar")) == nil || (DateTime.now - @version.date) > 3600
      
      #      p Time.now - @version.date
      data = DownloadData::NuSTAR.download_data#(params[:startdate],params[:enddate])
      @version = NasaVersion.new#(:version => "swift"+params[:startdate], :content => data, :date => Time.now)
      @version._id = "nustar"#+params[:startdate]+params[:enddate]
      @version.content = data
      @version.date = Time.now
      @version.save
      
    end
    render :json => @version.content
#    data = DownloadData::NuSTAR.download_data()
#    render :json => data
  end

  def herschel
        if (@version = NasaVersion.find("herschel"+params[:startdate])) == nil || (DateTime.now - @version.date) > 3600
      
      #      p Time.now - @version.date
      data = DownloadData::Herschel.download_data(params[:startdate])#,params[:enddate])
      @version = NasaVersion.new#(:version => "swift"+params[:startdate], :content => data, :date => Time.now)
      @version._id = "herschel"+params[:startdate]#+params[:enddate]
      @version.content = data
      @version.date = Time.now
      @version.save
      
    end
    render :json => @version.content
#
 #   data = DownloadData::Herschel.download_data(params[:startdate])
 #   render :json => data
  end

private
  
  def control_params
    
    if params[:startdate] == nil && params[:enddate] == nil
      render :inline => "error"
    end
  end

end


#require 'sinatra'

# DATA ORA
# NOME TARGET
# 


module DownloadData

  class NasaObject
    attr_reader :startdate,:enddate,:target,:ra,:dec
    def initialize(startdate,enddate,target,ra,dec)
      @startdate,@enddate,@target,@ra,@dec = startdate,enddate,target,ra,dec
      @obj = [@startdate,@enddate,@target,@ra,@dec]
    end

    def to_json
      
      JSON.pretty_generate(@obj)
    end
    
    def object
      @obj
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
            targetname =  tr.children[9].children[0].text
#            targetname =  tr.children[11].children[1].text
            ra = tr.children[13].children[0].text
            dec =  tr.children[15].children[0].text
            roll = tr.children[17].children[0].text
            objects << NasaObject.new(startdate,enddate,targetname,ra,dec).object
          rescue
            next
          end
        end
      end
      p objects
      JSON.pretty_generate(objects)
    end
  end

  class Integral
    
    @domain = "http://integral.esac.esa.int/isocweb/"

    def initialize

    end

    def self.download_data(startdate,enddate)
      puts "http://integral.esac.esa.int/isocweb/schedule.html?selectMode=date&action=schedule&startDate=#{startdate.split("-").reverse.join("-")}&endDate=#{enddate.split("-").reverse.join("-")}"
      
      mech = Mechanize.new{|agent| agent.user_agent_alias = "Mac Safari"}
      
      data = mech.get("http://integral.esac.esa.int/isocweb/schedule.html?selectMode=date&action=schedule&startDate=#{startdate.split("-").reverse.join("-")}&endDate=#{enddate.split("-").reverse.join("-")}")

      link = data.link_with(:text => "here").href
      uri = URI(@domain+link)

      data = []
      n = 0
      CSV.parse(Net::HTTP.get(uri)) do |row|
        if(n == 0)
          n+=1
        else
          startdate = row[1]
          enddate = row[2]
          ra = row[5]
          dec = row[6]
          target = row[4] + " " + row[7]
          data << NasaObject.new(startdate,enddate,ra,dec,target).object
        end
      end

      JSON.pretty_generate(data)

    end
  end
  
  class NuSTAR
    def initialize
    end
    
    def self.download_data
      mech = Mechanize.new{|agent| agent.user_agent_alias = "Mac Safari"}
      
      data = mech.get("http://www.srl.caltech.edu/NuSTAR_Public/NuSTAROperationSite/AFT_Public.php")

      datan = []
      link = data.search("table").each do |table|
        if table.attributes["id"].value == "priority-table"
          1.upto(table.children.length-1) do |num|
            if(num & 1 == 1)
              values = table.children[num].children
              if values != nil
                #p values
                if values[4].children[0] != nil
                  startdate = values[0].text
                  enddate = values[1].text
                  target = values[3].text
                  ra = values[4].children[0].text
                  dec = values[5].children[0].text.chomp
                  datan << NasaObject.new(startdate,enddate,target,ra,dec).object
                end
              end
            end
          end
        end
      end

      JSON.pretty_generate(datan)

    end
  end

  class Herschel

    def initialize

    end

    def self.download_data(startdate)
      data = []
      CSV.parse( Net::HTTP.get(URI("http://herschel.esac.esa.int/logrepgen/observationlist.do?durationFrom=&odTo=&startTimeFrom#{startdate}T00%3A00%3A00Z&spgLabel=&d-49653-e=1&targetName=&odFrom=&obsId=&durationTo=&title=&qcFlags=&6578706f7274=1&startTimeTo=&isCalibration=false&proposalId=&itemsPerPage=10")).force_encoding('UTF-8')) do |row|
        ra =  row[2]
        dec = row[3]
        startdate = row[7]
        enddate = row[7]
        target = row[1]
        data << NasaObject.new(startdate,enddate,ra,dec,target).object
      end
      JSON.pretty_generate(data)
    end
  end
end
