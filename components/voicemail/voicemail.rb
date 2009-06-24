methods_for :dialplan do
  def handle_voicemail

    #Remove the preceding '+' from the Flowroute inbound calls
    #Other carriers may not send the plus
    #callerid.gsub!("+", "")
    rdnis.gsub!("+", "")

    case extension
    when 14155340223
      user = play_voicemail_greeting
      record_voicemail_message user
    end
  end

  def play_voicemail_greeting
    user = User.find_by_caller_id rdnis
    ahn_log.play_vm_greeting.debug user.latest_status.recording.filename
    play user.latest_status.recording.filename
    user
  end

  def record_voicemail_message(user)
    play 'beep'
    # TODO maybe add uuid to file name
    file_name = COMPONENTS.voicemail["voicemail_directory"] + "/#{user.id}_#{Time.now.to_i}"
    record file_name + ".#{COMPONENTS.voicemail["voicemail_format"]}"
    voicemail = user.voicemails.create!(:file_name => file_name)
  end

  #Future method to retrieve voicemails by user id over the phone
  def play_user_voicemails
    result = input :play => "fr/vm-login", :timeout => 3.seconds, :accept_key => "#"
    if result != ''
      user = User.find result.to_i
      user.voicemails.each do |voicemail|
        if voicemail.unread?
          play voicemail.file_name
        end
      end
    else
      play 'fr/invalid'
    end
    hangup
  end
  
end