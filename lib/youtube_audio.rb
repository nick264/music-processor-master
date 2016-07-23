class YoutubeAudio
	def self.fetch!(youtube_url, force=false)
		name = CGI::parse(URI.parse(youtube_url).query)["v"][0]
		fullpath = File.join(ROOT_DIR,"cache",name)
		yt_download_filename = fullpath + ".m4a"
		audio_filename = fullpath + ".aac"
		# wav_filename = fullpath + ".wav"
		YoutubeDL.download youtube_url, output: yt_download_filename, format: 140 if ( !File.exists?(audio_filename) && !File.exists?(yt_download_filename) ) || force
		`ffmpeg -i #{yt_download_filename} -vn -acodec copy #{audio_filename}` if !File.exists?(audio_filename) || force
		# `ffmpeg -i #{audio_filename} #{wav_filename}` if !File.exists?(wav_filename) || force

		`rm #{yt_download_filename}` if File.exists?(yt_download_filename)
		raise "Didn't create audio successfully" if !File.exists?(audio_filename)
		audio_filename
	end
end
