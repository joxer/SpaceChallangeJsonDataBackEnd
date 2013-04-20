class NasaVersion
  include Mongoid::Document

  field :version, :type => String
  field :content, :type => String
  field :date, :type => Date
#  referenced_in :version
end
