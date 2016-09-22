class Place
	include Mongoid::Document
  include ActiveModel::Model
	attr_accessor :id, :formatted_address, :location, :address_components

	def self.mongo_client
		@@db = Mongo::Client.new('mongodb://localhost:27017/test')
	end

	def self.collection
	  self.mongo_client['racers']
	end

	def self.load_all(file)
		docs = JSON.parse(file.read)
		collection.insert_many(docs)
	end

  def initialize(params={})
    @id = params[:_id].to_s
    @formatted_address = params[:formatted_address]
    @location = Point.new(params[:geometry][:geolocation])
    @address_components = params[:address_components].map{ |a| AddressComponent.new(a)} if !params[:address_components].nil?
  end


   def self.find_by_short_name(short_name)
    collection.find(:'address_components.short_name' => short_name)
  end

  def self.to_places(places)
    places.map do |place|
			(Place.new(place))
    end
  end

  def self.create_indexes
    collection.indexes.create_one(:'geometry.geolocation' => Mongo::Index::GEO2DSPHERE)
  end

  def self.remove_indexes
  	collection.indexes.drop_one('geometry.geolocation_2dsphere')
	end

end
