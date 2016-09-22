class Point
	attr_accessor :longitude, :latitude

	def intialize(params)
		if !params[:coordinates].nil?
			@longitude = params[:coordinates][0]
			@latitude = params[:coordinates][1]
		else
			@longitude = params[:lng]
			@latitude = params[:lat]
		end
	end

	def to_hash
		{
			:type => "Point",
			:coordinates => [@latitude, @longitude]
		}
	end


end
