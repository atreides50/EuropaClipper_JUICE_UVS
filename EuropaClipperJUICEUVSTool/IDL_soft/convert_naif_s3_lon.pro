pro convert_naif_s3_lon, lon_ss

  ; Convert a bunch of Longitude given by naif
  ; They already have to be converted into degrees

  n_long = n_elements(lon_ss)
  
  if n_long eq 1 then begin
    
    if lon_ss lt 0 then lon_ss =-lon_ss else lon_ss = 360.d -lon_ss
    
  endif else begin
    
    ind_neg = where(lon_ss lt 0., complement=ind_pos, /null)
    if ind_neg ne !null then lon_ss[ind_neg] = -lon_ss[ind_neg]
    if ind_pos ne !null then lon_ss[ind_pos] = 360.d -lon_ss[ind_pos]
    
  endelse

end