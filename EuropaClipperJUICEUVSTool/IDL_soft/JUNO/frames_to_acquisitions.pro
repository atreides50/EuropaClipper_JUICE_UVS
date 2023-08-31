pro frames_to_acquisitions, FRAME_TAG, HACK_RATE, SC_TIME_FIRST_HACK, SC_TIME_LAST_HACK, acq_info


numframes=size(FRAME_TAG, /n_elements)

  i=0
  acq_tag=FRAME_TAG[i]

; Get the first 2 bits of the tag (corresponding to the data type)
  acq_type=fix(FRAME_TAG[i]/(2.^14))

; Get the hack rate of that acquisition
  acq_hack_rate=HACK_RATE[i]
  acq_first_frame=i

;Get the number of frame with the same tag
  foo=where(FRAME_TAG eq acq_tag, anumframes)
  acq_last_frame=max(foo)
  acq_num_frames=anumframes
  i=max(foo)+1

; Here we put all the different acquisition performed within a single array
; along with their type, hack rate, first frame/last frame index
  while (i lt numframes-1) do begin
	   acq_tag=[acq_tag, FRAME_TAG[i]]
     acq_type=[acq_type, fix(FRAME_TAG[i]/(2.^14))]
     acq_hack_rate=[acq_hack_rate, HACK_RATE[i]]
     acq_first_frame=[acq_first_frame,i]
     foo=where(FRAME_TAG eq FRAME_TAG[i], anumframes)
     acq_last_frame=[acq_last_frame, max(foo)]
     acq_num_frames=[acq_num_frames, anumframes]
     i=max(foo)+1
  endwhile
  
  s=size(acq_tag,/n_elements)
  acq_start_end_time=dblarr(2,s)
  ; Compute the first/last frame time for every acquisition period
  acq_start_end_time[0,*] = SC_TIME_FIRST_HACK[acq_first_frame]
  acq_start_end_time[1,*] = SC_TIME_LAST_HACK[acq_last_frame]
  
  acq_info={acq_tag:acq_tag,acq_type:acq_type,acq_hack_rate:acq_hack_rate,acq_first_frame:acq_first_frame,acq_last_frame:acq_last_frame,acq_num_frames:acq_num_frames,acq_start_end_time:acq_start_end_time}


return
end



