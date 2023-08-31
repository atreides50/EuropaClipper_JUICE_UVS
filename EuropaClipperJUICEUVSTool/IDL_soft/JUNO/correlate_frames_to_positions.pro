pro correlate_frames_to_positions,hv,pos_info

foo=size(hv.position_num,/n_elements)/2.
frame_list=intarr(foo,3000)
frame_list[*]=-1
num_frames=intarr(foo)
pos_list=intarr(foo)
pos_obs_time=dblarr(foo)
num_missing_frames=intarr(foo)
pos_start_end=dblarr(2,foo)
position_per_frame=intarr(size(hv.frame_tag,/n_elements))
for i=0,foo-1 do begin
	test=where(hv.sc_time_first_hack lt hv.position_time[i*2+1] and hv.sc_time_last_hack gt hv.position_time[i*2],ntest)  ;there is the chance that I can get too many files here if there are multiple acquisitions at a given scan mirror position.  You have to cut them up later by using the tab_byte_numbers to figure out if more than one acquisition has occured. 
	if (ntest gt 0) then begin
		num_frames[i]=size(test,/n_elements)
		frame_list[i,0:num_frames[i]-1]=test
		pos_list[i]=hv.position_num[i*2]
		pos_obs_time[i]=hv.position_time[i*2+1]-hv.position_time[i*2]
		pos_start_end[0,i]=hv.position_time[i*2]
		pos_start_end[1,i]=hv.position_time[i*2+1]
		if (ntest gt 2) then begin
                  position_per_frame[test[1:num_frames[i]-2]]=pos_list[i]
		endif
		if (position_per_frame[test[0]] ne 0) then begin
			position_per_frame[test[0]]=-1
		endif else begin
			position_per_frame[test[0]]=pos_list[i]
		endelse
		if (ntest gt 1) then begin
		  if (position_per_frame[test[num_frames[i]-1]] ne 0) then begin
			  position_per_frame[test[num_frames[i]-1]]=-1
		  endif else begin
			  position_per_frame[test[num_frames[i]-1]]=pos_list[i]
		  endelse
		endif
		num_missing_frames[i]=frame_list[i,num_frames[i]-1]-frame_list[i,0]+1-num_frames[i]
	endif
endfor

foo=where(num_frames ne 0)
num_frames=num_frames(foo)
frame_list=frame_list[foo,*]
pos_list=pos_list[foo]
pos_obs_time=pos_obs_time[foo]
pos_start_end=pos_start_end[*,foo]
num_missing_frames=num_missing_frames[foo]

frame_list=frame_list[*,0:max(num_frames)-1]

pos_info = {frame_list:frame_list,pos_list:pos_list,pos_obs_time:pos_obs_time,pos_start_end:pos_start_end,num_frames:num_frames,num_missing_frames:num_missing_frames,position_per_frame:position_per_frame}

return
end


