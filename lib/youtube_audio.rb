class YoutubeAudio
	def self.fetch!(youtube_url, force=false)
		name = CGI::parse(URI.parse(youtube_url).query)["v"][0]
		fullpath = File.join(ROOT_DIR,"cache",name)
		video_filename = fullpath + ".m4a"
		audio_filename = fullpath + ".aac"
		# wav_filename = fullpath + ".wav"
		YoutubeDL.download youtube_url, output: video_filename if !File.exists?(video_filename) || force
		`ffmpeg -i #{video_filename} -vn -acodec copy #{audio_filename}` if !File.exists?(audio_filename) || force
		# `ffmpeg -i #{audio_filename} #{wav_filename}` if !File.exists?(wav_filename) || force
		audio_filename
	end
end
