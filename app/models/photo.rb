class Photo
	attr_accessor :id, :location
	attr_writer :contents

	def self.mongo_client
		Mongoid::Clients.default
	end

	def initialize(params = nil)
		if params.present?
			@id = params[:_id].to_s || params[:id]
			@location = Point.new(params[:metadata][:location])
			@place = params[:metadata][:place]
		end
		# @files = self.class.collection
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


end