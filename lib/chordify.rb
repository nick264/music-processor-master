class Chordify
	require 'yaml'

  def self.fetch!(youtube_url)
		result        = RestClient.post("http://chordify.net/upload/url", { url: youtube_url })
		result_parsed = JSON.parse(result)
		save_to_library(result_parsed)

    chords_raw = result_parsed["chords"]

    chords_raw.split("\n").map{ |x| x.split(";") }
  end

  def self.save_to_library(response)
  	`touch #{library_file}`
    data = YAML.load_file(library_file) || {}

		title = response["metadata"]["title"]
		key   = response["audio"]

		raise "invalid key length" if key.size < 5 # make sure we're reading real keys

		data[key] = title

		File.open(library_file,'w') { |f| f.write data.to_yaml }
  end

  def self.choose_from_library
  	if !File.exists?(library_file)
  		puts "No library yet"
  		return
  	end

  	library = YAML.load_file(library_file) || {}

  	library.to_a.each_with_index do |(key,title),i|
  		puts "#{i+1}.\t#{title}"
  	end

  	puts "Choose one"
  	choice = gets.chomp

  	if( choice.to_i.to_s != choice )
  		puts "invalid choice!"
  		return
  	end

  	library.to_a[choice.to_i - 1][0]
  end

  def self.regenerate_library
  	cache_dir = File.join(ROOT_DIR,"cache")
  	Dir.entries(cache_dir).each do |file|
  		next if file.start_with?('.')
  		key = File.join(cache_dir,file).split("/").last.split('.').first
  		begin
  			puts "Doing #{key}..."
  			Chordify.fetch!("https://www.youtube.com/watch?v=#{key}")
  		rescue => e
  			puts "Oops!  #{e.to_s}"
  		end
  	end

  	true
  end

  private

  def self.library_file
  	File.join(ROOT_DIR,'config','chordify-library.yml')
  end
end
