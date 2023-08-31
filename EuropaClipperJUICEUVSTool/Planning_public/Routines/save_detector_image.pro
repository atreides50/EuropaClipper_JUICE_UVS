pro save_detector_image, path_output, spacecraft, time_array_utc, wavelength, detector

;nx_detector = 2^12
;ny_detector = 2^12
;
;DX = indgen(nx_detector)
DY = [1444:2452:1]

for it= 0,n_elements(time_array_utc)-1 do begin

  fileout= path_output+spacecraft+'_'+$
    strmid(time_array_utc[it],0,4)+strmid(time_array_utc[it],5,2)+strmid(time_array_utc[it],8,2)+'T'+strmid(time_array_utc[it],11,2)+strmid(time_array_utc[it],14,2)+strmid(time_array_utc[it],17,2)+'.sav'

  time_utc_output = time_array_utc[it]
  detector_output = detector[*,*,it]
  
  save, filename=fileout, time_utc_output, wavelength, DY, detector_output, /compress
endfor



end