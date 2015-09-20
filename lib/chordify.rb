class Chordify
  def self.fetch!(youtube_url)
    result       = RestClient.post("http://chordify.net/upload/url", { url: youtube_url })
    chords_raw = JSON.parse(result)["chords"]

    chords_raw.split("\n").map{ |x| x.split(";") }
  end
end
