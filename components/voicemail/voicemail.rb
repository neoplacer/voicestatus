methods_for :global do
  # It generates an audio file based on a given text status
  # @param [String] the text status to be converted to an audio file
  # @return [String] the file_name of the audio file
  def generate_tts_file(text_status)
    text_status = sprintf("%p", text_status)
    file_name = '/tmp/' + new_guid
    system("echo \"#{text_status}\" | text2wave -o #{ file_name + '.ulaw' } -otype ulaw")
    ahn_log.play_vm_greeting.debug file_name
    file_name
  end
end

methods_for :dialplan do
  def handle_voicemail

    # Remove the preceding '+' from the Flowroute inbound calls
    # Other carriers may not send the plus
    callerid.to_s.gsub!("+", "")  

    case extension
      when 14155340223
        if rdnis.blank?
          play_user_voicemails
        else
          rdnis.to_s.gsub!("+", "")
          play_voicemail_greeting
        end
    end
  end

  # It locates the user by callerid and plays his voicemails
  def play_user_voicemails
    user = locate_user(callerid)
    if user
      play_voicemails(user)
    else
      play "invalid"
    end
  end

  # It locates the user by rdnis and plays his voicemail greeting
  def play_voicemail_greeting
    user = locate_user(rdnis)
    if user
      play_greeting(user)
      record_voicemail_message(user)
    else
      play "invalid"
    end
  end

  # It locates the user based on the given phone number
  # @param [String] phone number of the user
  # @return [User] the user located or nil.                                                    �
  def locate_user(phone_number)
    User.find_by_phone_number(phone_number)
  end

  # It plays user's voicemail greeting status as a recorded file or by Text to Speech (TTS)
  # @param [User] user whose voicemail greeting will be played
  def play_greeting(user)
    sleep 2
    status = user.latest_status
    if status.instance_of? VoiceStatus
      ahn_log.play_vm_greeting.debug user.latest_status.recording.filename
      play user.latest_status.recording.filename
    else
      play generate_tts_file(status.stat)
    end
  end

  # It records voicemail message for the given user
  # @param [User] the user to leave voicemail messages for
  def record_voicemail_message(user)
    play 'beep'
    # TODO maybe add uuid to file name
    file_name = COMPONENTS.voicemail["voicemail_directory"] + "/#{user.id}_#{Time.now.to_i}"
    record file_name + ".#{COMPONENTS.voicemail["voicemail_format"]}"
    voicemail = user.voicemails.create!(:file_name => file_name)
  end

  # It plays the voicemails for the given user
  # @param [User] the user whose voicemails should be played back
  def play_voicemails(user)
    user.voicemails.each do |voicemail|
      if voicemail.unread?
        play voicemail.file_name
        voicemail.user_read!
        play 'beep'
        play generate_tts_file('Playing next message')
        sleep 'beep'
      end
    end
    hangup
  end
end