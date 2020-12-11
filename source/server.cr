require "kemal"
require "./audio"

module Shoutcast::Server
	CHUNK_SIZE = 32768

	@@stream = Array(String).new
	class_property stream

	@@skipper = Channel(Bool).new
	class_property skipper

	extend Audio

	serve_static false
	
	get "/" do | context |
		context.response.content_type = "audio/mpeg"
		
		buf_data = uninitialized UInt8[CHUNK_SIZE]
		buffer = Bytes.new pointer: buf_data.to_unsafe, size: CHUNK_SIZE
		connected =  true 

		while connected
			file = Path["./public/jingles/1.mp3"]
			audio_pipe file do | pipe |
				until (count = pipe.read buffer) == 0
					# select
					# when skipper.recieve then break
					# else
						if context.response.closed?
							connected = false
							break
						end
						
						if count > CHUNK_SIZE
							puts "got read count #{count} that was larger than the buffer size #{CHUNK_SIZE}"
							raise "Internal server error: invalid buffer size"
						end

						context.response.write Bytes.new buffer.to_unsafe, size: count, read_only: true
					# end
				end
			end
		end
	end

	post "/stream" do | context |
		HTTP::FormData.parse(context.request) do | upload |
			filename = upload.filename

			if !filename.is_a?(String)
				p "No filename provided"
			else
				file = File.tempfile(filename).path
				File.write(file, upload.body)
				stream.push(file)
			end
		end
	end

	get "/skip" do | context |
		skipper.send true
	end

	Kemal.run
end