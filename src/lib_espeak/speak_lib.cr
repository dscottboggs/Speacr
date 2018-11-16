# /***************************************************************************
#  *   Copyright (C) 2005 to 2012 by Jonathan Duddington                     *
#  *   email: jonsd@users.sourceforge.net                                    *
#  *                                                                         *
#  *   This program is free software; you can redistribute it and/or modify  *
#  *   it under the terms of the GNU General Public License as published by  *
#  *   the Free Software Foundation; either version 3 of the License, or     *
#  *   (at your option) any later version.                                   *
#  *                                                                         *
#  *   This program is distributed in the hope that it will be useful,       *
#  *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
#  *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
#  *   GNU General Public License for more details.                          *
#  *                                                                         *
#  *   You should have received a copy of the GNU General Public License     *
#  *   along with this program; if not, see:                                 *
#  *               <http://www.gnu.org/licenses/>.                           *
#  ***************************************************************************/

module Speacr
  @[Link("espeak")]
  lib LibEspeak
    #   SPEAK_LIB_H =
    #   ESPEAK_API =

    # Revision 2: Added parameter "options" to eSpeakInitialize()
    # Revision 3: Added espeakWORDGAP to  espeak_PARAMETER
    # Revision 4: Added flags parameter to espeak_CompileDictionary()
    # Revision 5: Added espeakCHARS_16BIT
    # Revision 6: Added macros: RATE_MINIMUM, RATE_MAXIMUM, RATE_NORMAL
    # Revision 7:  24.Dec.2011
    #  - Changed espeak_EVENT structure to add id.string[] for phoneme
    #    mnemonics.
    #  - Added espeakINITIALIZE_PHONEME_IPA option for espeak_Initialize() to
    #    report phonemes as IPA names.
    # Revision 8: Added function espeak_TextToPhonemes(). (26.Apr.2013)
    # Revision 9: Changed function espeak_TextToPhonemes(). (30.May.2013)
    API_REVISION = 9
    # values for 'value' in espeak_SetParameter(espeakRATE, value, 0), nominally
    # in words-per-minute
    enum Rate
      Minimum =  80
      Maximum = 450
      Normal  = 175
    end
    INITIALIZE_PHONEME_EVENTS = 0x0001
    INITIALIZE_PHONEME_IPA    = 0x0002
    INITIALIZE_DONT_EXIT      = 0x8000
    SSML                      =   0x10
    PHONEMES                  =  0x100
    ENDPAUSE                  = 0x1000
    KEEP_NAMEDATA             = 0x2000

    enum TextEncoding
      Auto
      UTF_8
      EightBit
      WChar
      SixteenBit
    end
    # When a message is supplied to `synth()`, the request is buffered and
    # `synth()` returns. When the message is really processed, the callback
    # function will be repeatedly called.
    # In AudioOutput::Retrieval mode, the callback function supplies to the
    # calling program the audio data and an event list terminated by
    # EventType::ListTerminated (0).
    # In AudioOutput::Playback mode, the callback function is called as soon as
    # an event happens.
    # For example suppose that the following message is supplied to espeak_Synth:
    # > "hello, hello."
    #
    # Once processed in AudioOutput::Playback mode, it could lead to 3 calls of
    # the callback function :
    # ### Block 1:
    # <audio data>,
    # List of events: EventType::Sentence + EventType::Word + EventType::ListTerminated
    # ### Block 2:
    # <audio data>,
    # List of events: EventType::Word + EventType::End + EventType::ListTerminated
    # Block 3:
    # no audio data,
    # List of events: EventType::MessageTerminated + EventType::ListTerminated
    #
    # Once processed in AudioOutput::Playback mode, it could lead to 5 calls of
    # the callback function:
    #  - EventType::Sentence
    #  - EventType::Word (call when the sounds are actually played)
    #  - EventType::Word
    #  - EventType::End (call when the end of EventType::Sentence is actually played.)
    #  - EventType::MessageTerminated
    #
    # The EventType::MessageTerminated event is the last event. It can inform the
    # calling program to clear the user data related to the message. So if the
    # synthesis must be stopped, the callback function is called for each
    # pending message with the EventType::MessageTerminated event.

    # A MARK event indicates a <mark> element in the text.
    # A PLAY event indicates an <audio> element in the text, for which the
    # calling program should play the named sound file.
    enum EventType : LibC::UInt
      # Retrieval mode: terminates the event list.
      ListTerminated
      # Start of word
      Word
      # Start of sentence
      Sentence
      Mark
      # Audio element
      Play
      # End of sentence or clause
      End
      # End of message
      MessageTerminated
      # Phoneme, if enabled in `.initialize`
      Phoneme
      # internal use; set sample rate
      SampleRate
    end

    struct Event
      type : EventType
      unique_identifier : LibC::UInt
      text_position : LibC::Int
      length : LibC::Int
      audio_position : LibC::Int
      sample : LibC::Int
      user_data : Void*
      id : EspeakEventID
    end

    union EspeakEventID
      number : Int64
      name : LibC::Char*
      string : LibC::Char*
    end

    enum PositionType : LibC::UInt
      Character = 1
      Word
      Sentence
    end
    enum AudioOutput : LibC::UInt
      # plays the audio data, supplies events to the calling program
      Playback
      # supplies audio data and events to the calling program
      Retrieval
      # Like Retrieval but doesn't return until synthesis is completed
      Synchronous
      # Like Playback but doesn't return until synthesis is completed
      SynchronousPlayback
    end
    enum ErrorCode : LibC::Int
      InternalError = -1
      OK
      BufferFull
      NotFound
    end
    # Must be called before any synthesis functions are called.
    #
    # - **output**: the audio data can either be played aloud by eSpeak or
    #   passed back by the SynthCallback function.
    # - **buffer_length**: The length in mS of sound buffers passed to the
    #   SynthCallback function. Value=0 gives a default of 200mS. This paramater
    #   is only used for AUDIO_OUTPUT_RETRIEVAL and AUDIO_OUTPUT_SYNCHRONOUS
    #   modes.
    # - **path**: The directory which contains the espeak-data directory, or
    #   NULL for the default location.
    # - **options**:
    #  - set *bit 0* to allow EventType::Phoneme events.
    #  - set *bit 1* to EventType::Phoneme events give IPA phoneme names, not
    #    eSpeak phoneme names
    #  - set *bit 15* to 1=don't exit if espeak_data is not found (used for --help)
    # - **Returns**: sample rate in Hz or ErrorCode::InternalError
    fun initialize = espeak_Initialize(AudioOutput, LibC::Int, LibC::Char*, LibC::Int) : LibC::Int
    # Must be called before any synthesis functions are called.
    # This specifies a function in the calling program which is called when a
    # buffer of speech sound data has been produced.
    #
    # the callback function is of the form
    # ```
    # SynthCallback(
    #   audio_data : Short*,
    #   number_of_samples : Int,
    #   events : [] of Event
    # ) -> Int
    # ```
    # - **audio data** is a null-terminated .wav data
    # - **number_of_samples** is the number of entries in wav.  This number may
    #   vary, may be less than the value implied by the buflength parameter
    #   given in initialize, and may sometimes be zero (which does NOT indicate
    #   end of synthesis).
    # - **events**: Event objects which indicate word and sentence events, and also
    #   the occurance if <mark> and <audio> elements within the text.  The list
    #   of events is terminated by an event of type = 0.
    fun set_synth_callback = espeak_SetSynthCallback(Proc(LibC::Short*, LibC::Int, Event*, LibC::Int)*) : Void
    # This function may be called before synthesis functions are used, in order
    # to deal with <audio> tags.  It specifies a callback function which is
    # called when an <audio> element is encountered and allows the calling
    # program to indicate whether the sound file which is specified in the
    # <audio> element is available and is to be played.
    #
    # the callback function is of the form
    # `UriCallback(type : Int, uri : Char*, base : Char*) -> Int`
    # - **type**:  type of callback event.  Currently only 1= <audio> element
    # - **uri**: the "src" attribute from the <audio> element
    # - **base**: the "xml:base" attribute (if any) from the <speak> element
    # - **return**:
    #  0. place a PLAY event in the event list at the point where the <audio>
    #     element occurs.  The calling program can then play the sound at that
    #     point.
    #  1. don't play the sound, but speak the text alternative.
    fun set_uri_callback = espeak_SetUriCallback((LibC::Int, LibC::Char*, LibC::Char*) -> LibC::Int*) : Void
    # Synthesize speech for the specified text.  The speech sound data is passed
    # to the calling program in buffers by means of the callback function
    # specified by `set_synth_callback()`. The command is asynchronous: it is
    # internally buffered and returns as soon as possible. If `initialize()` was
    # previously called with AUDIO_OUTPUT_PLAYBACK as argument, the sound data
    # are played by eSpeak.
    #
    # argument names:
    # - **text**: The text to be spoken, terminated by a zero character. It may be
    #   either 8-bit characters, wide characters (wchar_t), or UTF8 encoding.
    #   Which of these is determined by the "flags" parameter.
    # - **size**: Equal to (or greatrer than) the size of the text data, in bytes.
    #   This is used in order to allocate internal storage space for the text.
    #   This value is not used for AudioOutput::Synchronous mode.
    # - **position**: The position in the text where speaking starts. Zero
    #   indicates speak from the start of the text.
    # - **position type**: Determines whether "position" is a number of
    #   characters, words, or sentences.
    # - **end position**: If set, this gives a character position at which
    #   speaking will stop.  A value of zero indicates no end position.
    # - **flags**: Bitwise or of TextEncoding and SSML, PHONEMES, and END_PAUSE
    #   flags.
    # - **unique_identifier**: This must be either NULL, or point to an integer
    #   variable to which eSpeak writes a message identifier number. eSpeak
    #   includes this number in Espeak::Event messages which are the result of
    #   this call of `synth()`.
    # - **user data**: a pointer (or NULL) which will be passed to the callback
    #   function in Event messages.
    fun synth = espeak_Synth(Void*, LibC::SizeT, LibC::UInt, PositionType, LibC::UInt, LibC::UInt, LibC::UInt*, Void*) : ErrorCode
    # Synthesize speech for the specified text.  Similar to `synth()` but the
    # start position is specified by the name of a <mark> element in the text.
    #
    # Arguments:
    # - text
    # - size
    # - **index_mark**:  The "name" attribute of a <mark> element within the
    #   text which specified the point at which synthesis starts. UTF8 string.
    # - end_position
    # - flags
    # - unique_identifier
    # - user_data
    fun synth_mark = espeak_Synth_Mark(Void*, LibC::SizeT, LibC::Char*, LibC::UInt, LibC::UInt, LibC::UInt*, Void*) : ErrorCode
    # Speak the name of a keyboard key. If key_name is a single character, it
    # speaks the name of the character. Otherwise, it speaks key_name as a text
    # string.
    fun key = espeak_Key(LibC::Char*) : ErrorCode
    # Speak the name of the given character
    fun char = espeak_Char(LibC::UShort) : ErrorCode
    enum Parameter : LibC::UInt
      Silence
      # speaking speed in word per minute.  Values 80 to 450.
      Rate
      # volume in range 0-200 or more. 0=silence, 100=normal full volume,
      # greater values may produce amplitude compression or distortion
      Volume
      # base pitch, range 0-100.  50=normal
      Pitch
      # pitch range, range 0-100. 0-monotone, 50=normal
      PitchRange
      # which punctuation characters to announce:
      # value in PunctuationType; see `get_parameter()` to specify which
      # characters are announced.
      Punctuation
      # announce capital letters by:
      # 0  => none
      # 1  => sound icon
      # 2  => spelling
      # 3+ => by raising pitch.  This values gives the amount in Hz by which the
      # pitch of a word raised to indicate it has a capital letter.
      Capitals
      # pause between words, units of 10mS (at the default speed)
      WordGap
      Options
      Intonation
      Reserved1
      Reserved2
      Emphasis
      LineLength
      VoiceType
      NoSpeech
    end
    enum PunctuationType : LibC::UInt
      None
      All
      Some
    end

    enum PhonemeType : LibC::Int
      # No phoneme output (default)
      None
      # Output the translated phoneme symbols for the text
      Translated
      # Like Translated, but also output a trace of how the translation was
      # done (matching rules and list entries)
      TranslatedWithTrace
      # Like Translated, but produces IPA rather than ascii phoneme names
      IPA
    end
    # Chooses whether to set the Parameter absolutely or relative to its current
    # value
    enum ParameterSetMode : LibC::Int
      Absolute
      Relative
    end
    # Sets the value of the specified parameter.
    fun set_parameter = espeak_SetParameter(Parameter, LibC::Int, ParameterSetMode) : ErrorCode
    # If the second argument is 0, returns the default value for the given
    # Parameter, if it's one, returns the current value
    fun get_parameter = espeak_GetParameter(Parameter, LibC::Int) : LibC::Int
    # Specified a list of punctuation characters whose names are to be spoken
    # when the value of the Punctuation parameter is set to "some".
    fun set_punctuation_list = espeak_SetPunctuationList(LibC::UShort*) : ErrorCode
    # Controls the output of phoneme symbols for the text
    #
    # TODO: the headers have the second argument listed as a "FILE*", which I
    # assume to be a file descriptor? but I could be wrong, so maybe that
    # shouldn't be a LibC::Int*
    fun set_phoneme_trace = espeak_SetPhonemeTrace(PhonemeType, LibC::Int*) : Void
    # Translates text into phonemes.  Call `set_voice()` or
    # `set_voice_by_name()` first, to select a language.
    #
    # It returns a pointer to a character string which contains the phonemes for
    # the text up to end of a sentence, or comma, semicolon, colon, or similar punctuation.
    #
    # #### Arguments:
    # - **text pointer**: The address of a pointer to the input text which is
    #   terminated by a zero character. On return, the pointer has been advanced
    #   past the text which has been translated, or else set to NULL to indicate
    #   that the end of the text has been reached.
    # - **text mode**: type of character codes
    # - **phoneme mode**: bitfield options:
    #   *bits 0-3*:
    #   0= just phonemes.
    #   1= include ties (U+361) for phoneme names of more than one letter.
    #   2= include zero-width-joiner for phoneme names of more than one letter.
    #   3= separate phonemes with underscore characters.
    #   *bits 4-7*:
    #   0= eSpeak's ascii phoneme names.
    #   1= International Phonetic Alphabet (as UTF-8 characters).
    fun text_to_phonemes = espeak_TextToPhonemes(Void**, TextEncoding, LibC::Int) : LibC::Char*
    # Compile pronunciation dictionary for a language which corresponds to the
    # currently selected voice. The required voice should be selected before
    # calling this function.
    # #### Arguments
    # - **path**: The directory which contains the language's '_rules' and
    #   '_list' files. 'path' should end with a path separator character ('/').
    # - **log**: Stream for error reports and statistics information. If
    #   log == NULL then stderr will be used.
    # - **flags**: Bit 0: include source line information for debug purposes
    #   (This is displayed with the -X command line option).
    #
    # TODO: the headers have the second argument listed as a "FILE*", which I
    # assume to be a file descriptor? but I could be wrong, so maybe that
    # shouldn't be a LibC::Int*
    fun compile_dictionary = espeak_CompileDictionary(LibC::Char*, LibC::Int*, LibC::Int) : Void

    # The Voice structure is used for two purposes:
    # 1.  To return the details of the available voices.
    # 2.  As a parameter to `set_voice()` in order to specify
    # selection criteria.
    #
    # In the first case, the "languages" field consists of a list of (UTF8)
    # language names for which this voice may be used, each language name in
    # the list is terminated by a zero byte and is also preceded by a single
    # byte which gives a "priority" number.  The list of languages is
    # terminated by an additional zero byte.
    #
    # A language name consists of a language code, optionally followed by one
    # or more qualifier (dialect) names separated by hyphens (eg. "en-uk").
    # A voice might, for example, have languages "en-uk" and "en". Even without
    # "en" listed, voice would still be selected for the "en" language (because
    # "en-uk" is related) but at a lower priority.
    #
    # The priority byte indicates how the voice is preferred for the language.
    # A low number indicates a more preferred voice, a higher number indicates
    # a less preferred voice.

    # In the second case, the "languages" field consists simply of a single
    # (UTF8) language name, with no preceding priority byte.
    struct Voice
      name : LibC::Char*
      languages : LibC::Char*
      identifier : LibC::Char*
      gender : Gender
      age : LibC::Int
      variant : LibC::Char
      xx1 : LibC::Char
      score : LibC::Int
      spare : Void*
    end

    enum Gender
      NotSpecified
      Male
      Female
    end

    # Reads the voice files from espeak-data/voices and creates an array of
    # Voice pointers. The list is terminated by a NULL pointer.
    fun list_voices = espeak_ListVoices(Voice*) : Voice**
    # Searches for a voice with a matching "name" field.  Language is not
    # considered. "name" is a UTF8 string.
    fun set_voice_by_name = espeak_SetVoiceByName(LibC::Char*) : ErrorCode
    # An espeak_VOICE structure is used to pass criteria to select a voice. Any
    # of the following fields may be set:
    #  - **name**: NULL, or a voice name
    #  - **languages**: NULL, or a single language string (with optional
    #    dialect), eg. "en-uk", or "en"
    #  - **gender**: 0=not specified, 1=male, 2=female
    #  - age: 0=not specified, or an age in years
    #  - variant  After a list of candidates is produced, scored and sorted,
    #    "variant" is used to index that list and choose a voice. variant=0
    #    takes the top voice (i.e. best match). variant=1 takes the next
    #    voice, etc
    fun set_voice = espeak_SetVoiceByProperties(Voice*) : ErrorCode
    # Returns the espeak_VOICE data for the currently selected voice. This is
    # not affected by temporary voice changes caused by SSML elements such as
    # <voice> and <s>
    fun current_voice = espeak_GetCurrentVoice : Voice*
    # Stop immediately synthesis and audio output of the current text. When this
    # function returns, the audio output is fully stopped and the synthesizer
    # is ready to synthesize a new message.
    fun cancel = espeak_Cancel() : ErrorCode
    # Returns 1 if audio is played, 0 otherwise.
    fun playing? = espeak_IsPlaying() : LibC::Int
    # This function returns when all data have been spoken.
    fun synchronize = espeak_Synchronize() : ErrorCode
    # last function to be called.
    fun terminate = espeak_Terminate() : ErrorCode
    # Returns the version number string, and sets the argument to the path to
    # espeak_data
    fun info = espeak_Info(LibC::Char**) : LibC::Char*
  end
end
