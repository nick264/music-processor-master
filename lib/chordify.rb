class Chordify
	require 'yaml'
  ACCOUNT_EMAIL = 'nicholas.sedlet@gmail.com'
  ACCOUNT_PASSWORD = 'thisismycoolpassword'
  @@login_cookies = nil
  @@library = nil

  def self.login!
    return @@login_cookies if @@login_cookies

    @@login_cookies = RestClient.post("https://chordify.net/user/signin", { 
        email:    ACCOUNT_EMAIL,
        password: ACCOUNT_PASSWORD
    } ) do |resp,req,res|
      raise "Expected response code 302!  Got #{resp.code}" unless resp.code == 302  
      resp.cookies
    end
  end

  def self.fetch_song_data!(youtube_id, max_retries = 4)
    login!
    post_song_response = RestClient.post("https://chordify.net/song", { url: "https://www.youtube.com/watch?v=#{youtube_id}", pseudoId: "youtube:#{youtube_id}" }, { cookies: @@login_cookies} )
    post_song_response_parsed = JSON.parse(post_song_response)
    
    if post_song_response_parsed['status'] == 'error'
      raise "Encountered error - response: #{post_song_response_parsed.inspect}"
    elsif post_song_response_parsed['status'] == 'inqueue'
      if max_retries > 0
        sleep_time = 3
        puts "In progress!  Checking again in #{sleep_time} seconds"
        sleep(sleep_time)
        fetch_song_data!(youtube_key,max_retries - 1)
      else
        raise "Still in queue and out of retries!  #{post_song_response_parsed.inspect}"
      end
    elsif post_song_response_parsed['status'] == 'done'
      slug = post_song_response_parsed['slug']
      data_response = RestClient.get("https://chordify.net/song/getdata//#{slug}", { cookies: @@login_cookies } )
      JSON.parse(data_response)
    end
  end

  def self.fetch!(youtube_url, force_query = false)
    key = CGI.parse(URI.parse(youtube_url).query)["v"][0]

    if ( entry = library[key] ).nil? || entry[:response].nil? || force_query
      puts "fetching from chordify..."
      song_data = fetch_song_data!(key)
		  save_to_library(song_data)
    else
      puts "loading from cache..."
      song_data = library[key][:response]
    end

    song_data['song']['chords']
  end

  def self.save_to_library(response)
  	`touch #{library_file}`
    data = library(true)

		title = response['song']['metadata']['title']
		key   = response['song']['audio']

		raise "invalid key length" if key.size < 5 # make sure we're reading real keys
		data[key] = { title: title, response: response }
		File.open(library_file,'w') { |f| f.write data.to_yaml }
  end

  def self.choose_from_library
  	if !File.exists?(library_file)
  		puts "No library yet"
  		return
  	end

  	library.to_a.each_with_index do |(key,data),i|
  		puts "#{i+1}.\t#{data[:title]}"
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
    keys = library.keys
    # keys.each{ |k| raise "Couldn't find file for key: #{k}!" unless File.exists?(File.join(cache_dir,"#{k}.aac")) }

  	keys.each do |key|
  		begin
  			puts "Doing #{key}..."
  			Chordify.fetch!("https://www.youtube.com/watch?v=#{key}",true)
  		rescue => e
  			puts "Oops!  #{e.to_s}"
  		end
  	end

  	true
  end

  def self.library(reload = false)
    return @@library if @@library && !reload
    @@library = YAML.load_file(library_file) || {}
  end

  private

  def self.library_file
  	File.join(ROOT_DIR,'config','chordify-library.yml')
  end
end
