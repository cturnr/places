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

def self.find(id)
    place = collection.find(_id: BSON::ObjectId.from_string(id)).first
    place.nil? ? nil : Place.new(place)
  end

	def self.all(offset = 0, limit = 0)
		result = collection
			.find
			.skip(offset)
			.limit(limit)

		result.map {|place| Place.new(place)}
	end

	def destroy
		id = BSON::ObjectId.from_string(@id)
    self.class.collection.delete_one(:_id => id)
	end

	def self.get_address_components(sort = nil, offset = nil, limit = nil)
    options = []
    options << {:$sort => sort} if sort.present?
    options << {:$skip => offset} if offset.present?
    options << {:$limit => limit} if limit.present?
    collection.find.aggregate(
      [
        {:$project => {_id: 1, address_components: 1, formatted_address: 1, geometry: {geolocation: 1}}},
        {:$unwind => '$address_components'}
      ].concat(options)
    )
  end

	def self.get_country_names 
		    collection.find.aggregate(
      [
        {:$project => {_id: 0, address_components: {long_name: 1, types: 1}}},
        {:$unwind => '$address_components'},
        {:$unwind => '$address_components.types'},
        {:$match => {'address_components.types' => 'country'}},
        {:$group => {_id: '$address_components.long_name'}}
      ]).map { |p| p[:_id] }
	end

  def self.find_ids_by_country_code(country_code)
    collection.find.aggregate(
      [
        {:$project => {_id: 1, address_components: 1}},
        {:$unwind => '$address_components'},
        {:$unwind => '$address_components.types'},
        {:$match => {'address_components.types' => 'country', 'address_components.short_name' => country_code}},
        :$project => {_id: 1}
      ]).map { |p| p[:_id].to_s }
  end

  def self.create_indexes
    collection.indexes.create_one(:'geometry.geolocation' => Mongo::Index::GEO2DSPHERE)
  end

  def self.remove_indexes
  	collection.indexes.drop_one('geometry.geolocation_2dsphere')
	end

	def self.near(point, max_meters = nil)
		collection.find('geometry.geolocation' => {:$near => {:$geometry => point.to_hash, :$maxDistance => max_meters}})
	end

	def near(max_meters = nil)
		places = self.class.near(@location, max_meters)
		places.nil? ? nil : places.map { |p| Place.new(p)}
	end

  def photos(offset = 0, limit = 0)
    Photo.find_photos_for_place(@id).limit(0).skip(0).map{|p|Photo.new(p)}
  end

  def persisted?
  	!@id.nil?
  end
  	

end

