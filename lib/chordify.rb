class Chordify
	def self.fetch!(youtube_url)
		# json = RestClient.get("http://chordify.net/song/getdata/the-antlers-two-tisusernamesucks")
		# data = JSON.parse(json)

		# data["song"]["chords"]

		result     = RestClient.post("http://chordify.net/upload/url", { url: youtube_url })
		chords_raw = JSON.parse(result)["chords"]
		
		chords_raw.split("\n").map{ |x| x.split(";") }
	end
end
