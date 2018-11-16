# TODO: Write documentation for `Speacr`
require "./lib_espeak/*"
module Speacr
  VERSION = "0.1.0"

  class Speaker
    DEFAULT_BUFFER_LENGTH = 0
    private enum FinishedStatus
      Done
    end
    @done_chan = Channel(FinishedStatus).new
    @audio_stream = Channel(Int16).new
    @speaker_id : UInt32 = Random.new.next_u
    @synth_callback : Proc(LibC::Short*, LibC::Int, LibEspeak::Event*, LibC::Int)

    def initialize(say_aloud = false)
      @sample_rate = LibEspeak.initialize(
        say_aloud ? LibEspeak::AudioOutput::SynchronousPlayback : LibEspeak::AudioOutput::Retrieval,
        0, # default buffer length of around 200ms
        nil,
        0)
      @synth_callback = ->(
        audio_data : LibC::Short*,
        number_of_samples : Int32,
        events : LibEspeak::Event*
      ) do
        offset = 0
        until (event = (events + offset).value).type === LibEspeak::EventType::ListTerminated
          offset += 1
          unless event.unique_identifier === @speaker_id
            STDERR.puts "\
             got event from speaker ID #{event.unique_identifier}, \
             expected #{@speaker_id}"
          end
        end
        number_of_samples.times do |offset|
          sample = (audio_data + offset).value
          if sample == 0
            @done_chan.send FinishedStatus::Done
            break
          end
          @audio_stream.send sample
        end
        return 1
      end
      LibEspeak.set_synth_callback(pointerof(@synth_callback))
    end

    def say(text)
      LibEspeak.synth(
        text,
        text.size,
        0, # start offset
        LibEspeak::PositionType::Character,
        0, # end offset
        0, # no flags
        pointerof(@speaker_id),
        nil) # no "user data" pointer
      self
    end

    def gets
      audio_clip = [] of Int16
      until (data = Channel.receive_first(@done_chan, @audio_stream)) === FinishedStatus::Done
        audio_clip << data.as Int16
      end
      audio_clip
    end
  end
end
