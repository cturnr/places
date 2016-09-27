class Photo
	include ActiveModel::Model

	attr_accessor :id, :location
	attr_writer :contents

	def self.mongo_client
		Mongoid::Clients.default
	end

	def self.collection
    mongo_client.database.fs
  end

	def initialize(params = nil)
		if params.present?
			@id = params[:_id].to_s || params[:id]
			@location = Point.new(params[:metadata][:location])
			@place = params[:metadata][:place]
		end
		@files = self.class.collection
	end

	def persisted?
  	@id.present?
  end

	def save
    if persisted?
      description = {}
      description[:metadata] = {}
      description[:metadata][:location] = @location.to_hash
      description[:metadata][:place] = @place

      @files.find({_id: BSON::ObjectId.from_string(id)}).update_one(:$set => description)
			# self.class.mongo_client.database.fs.find(:_id => BSON::ObjectId(@id))
    else
    if @contents
      gps = EXIFR::JPEG.new(@contents).gps
      @location = Point.new(lat: gps.latitude, lng: gps.longitude)

      description = {}
      description[:content_type] = 'image/jpeg'
      description[:metadata] = {}
      description[:metadata][:location] = @location.to_hash
      description[:metadata][:place] = @place

      @contents.rewind
      grid_file = Mongo::Grid::File.new(@contents.read, description)
      id = self.class.mongo_client.database.fs.insert_one(grid_file)
      @id = id.to_s
      end
    end
  end

  def self.all(skip = 0, limit = nil)
  	docs = mongo_client.database.fs.find({}).skip(skip)
  	docs = docs.limit(limit) if !limit.nil?

  	docs.map do |doc|
  		Photo.new(doc)
  	end
  end

  def self.find(id)
  	doc = mongo_client.database.fs.find(:_id => BSON::ObjectId(id)).first
  	if doc.nil?
  		return nil
  	else
  		return Photo.new(doc)
  	end
  end

  def contents
  	doc = self.class.mongo_client.database.fs.find_one(:_id => BSON::ObjectId(@id))
  	if doc
  	  buffer = ""
  	  doc.chunks.reduce([]) do |x, chunk|
  	    buffer << chunk.data.data
  	  end
  	  return buffer
  	end
  end

  def destroy
  	self.class.mongo_client.database.fs.find(:_id => BSON::ObjectId(@id)).delete_one
  end

	def find_nearest_place_id(max_distance)
		place = Place.near(@location, max_distance).limit(1).projection(:_id => 1).first
		place.nil? ? nil : place[:_id]
	end

  def place
    @place.nil? ? nil : Place.find(@place)
  end

  def place=(place)
    @place = BSON::ObjectId.from_string( place.is_a?(Place) ? place.id : place)
  end

   def self.find_photos_for_place(id)
    id = id.is_a?(String) ? BSON::ObjectId.from_string(id) : id
    collection.find({'metadata.place': id})
  end

end