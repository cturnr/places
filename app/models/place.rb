class Place

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



end
