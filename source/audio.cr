module Shoutcast::Audio
	extend self

	def ffmpeg_mp3_cmd(file : Path) : String
		%<ffmpeg -i "#{file}" -vn -f mp3 - >
	end

	def audio_pipe(file : Path)
		args = ffmpeg_mp3_cmd file
		puts args
		Process.run args, shell: true do | process |
			sleep 0.1
			if process.terminated?
				status = process.wait 
				return if status.success?
				exit_code = if status.normal_exit?
					"exit code" + status.exit_code.to_s
				else
					"signal" + status.exit_code.to_s
				end
				raise "command #{args} failed with #{exit_code}"
			else
				yield process.output
			end
		end 
	end

	def stream_pipe(data : IO::Memory)
		
	end
end