class ColourLovers
	def self.fetch!(keywords = nil,hueOption=nil,resNum=0)
		result = RestClient.get('http://www.colourlovers.com/api/palettes/top', { params: { hueOption: hueOption, keywords: keywords, resultOffset: resNum, format: "json" } })
		palettes = JSON.parse(result)

		# `open #{palettes[0]["imageUrl"]}`

		palettes[0]["colors"]
	end
end

