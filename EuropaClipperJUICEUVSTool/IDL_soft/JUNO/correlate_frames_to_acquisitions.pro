pro correlate_frames_to_acquisitions,hv,acq_info

numframes=size(hv.frame_counter,/n_elements)

i=0
acq_tag=hv.frame_tag[i]
acq_type=fix(hv.frame_tag[i]/(2.^14))
acq_hack_rate=hv.hack_rate[i]
acq_first_frame=i
foo=where(hv.frame_tag eq acq_tag,anumframes)
acq_last_frame=max(foo)
acq_num_frames=anumframes

i=max(foo)+1

while (i lt numframes-1) do begin
	acq_tag=[acq_tag,hv.frame_tag[i]]
	acq_type=[acq_type,fix(hv.frame_tag[i]/(2.^14))]
	acq_hack_rate=[acq_hack_rate,hv.hack_rate[i]]
	acq_first_frame=[acq_first_frame,i]
	foo=where(hv.frame_tag eq hv.frame_tag[i],anumframes)
	acq_last_frame=[acq_last_frame,max(foo)]
	acq_num_frames=[acq_num_frames,anumframes]
	i=max(foo)+1
endwhile

s=size(acq_tag,/n_elements)
acq_start_end_time=dblarr(2,s)
acq_start_end_time[0,*]=hv.sc_time_first_hack[acq_first_frame]
acq_start_end_time[1,*]=hv.sc_time_last_hack[acq_last_frame]

acq_info={acq_tag:acq_tag,acq_type:acq_type,acq_hack_rate:acq_hack_rate,acq_first_frame:acq_first_frame,acq_last_frame:acq_last_frame,acq_num_frames:acq_num_frames,acq_start_end_time:acq_start_end_time}

return
end
