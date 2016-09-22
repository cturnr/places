class Place
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
    @address_components = params[:address_components].map{ |a| AddressComponent.new(a)} if !params[:address_components].nil?
    @formatted_address = params[:formatted_address]
    # @location = Point.new(params[:geometry][:geolocation])
  end

   def self.find_by_short_name(short_name)
    collection.find(:'address_components.short_name' => short_name)
  end

  def self.to_places(places)
    places.map do |place|
      return(Place.new(place))
    end
  end

end
