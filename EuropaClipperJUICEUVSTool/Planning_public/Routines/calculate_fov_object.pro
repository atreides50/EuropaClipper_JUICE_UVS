pro calculate_FOV_object, spacecraft, spacecraft_id, time_array_et, object, lat_boresight_AP_object, lon_boresight_AP_object, lat_boresight_SP_object, lon_boresight_SP_object,$
                          rate_boresight_object_AP, rate_boresight_object_SP, body_AP_angle, body_SP_angle
                          
; This routine calculates if the UVS AP or SP intersect with a given object (Jupiter, moon)
; and if so, it calculates the rate of the FOV drift on the object
; in km/second
;
; Vincent Hue, SwRI, 2022


  nt = n_elements(time_array_et)
  rate_boresight_sky_AP = fltarr(nt) - 999.
  rate_boresight_sky_SP = fltarr(nt) - 999.

  CASE 1 OF
    spacecraft eq 'Europa': begin
      boresight_frame_AP = 'EUROPAM_UVS_AP'
      boresight_frame_SP = 'EUROPAM_UVS_SP'
    end
    spacecraft eq 'JUICE': begin
      boresight_frame_AP = 'JUICE_UVS_AP'
      boresight_frame_SP = 'JUICE_UVS_SP'
    end
  end

  cspice_bodvrd, object, "RADII", 3, radii_object
  mean_radius = mean(radii_object) ; That is not true for oblate planet
  
  cspice_bodn2c, boresight_frame_AP, ID_AP, found_ID
  cspice_bodn2c, boresight_frame_SP, ID_SP, found_ID

  ; Define the size of the boundary vectors
  ROOM=100
  cspice_getfov, ID_AP, ROOM, shape, iframe_uvs, boresight_AP, bundry_AP
  cspice_getfov, ID_AP, ROOM, shape, iframe_uvs, boresight_SP, bundry_SP

  lat_boresight_AP_object = fltarr(nt) -999.
  lon_boresight_AP_object = fltarr(nt) -999.
  lat_boresight_SP_object = fltarr(nt) -999.
  lon_boresight_SP_object = fltarr(nt) -999.
  AP_found_object = intarr(nt)
  SP_found_object = intarr(nt)
  rate_boresight_object_AP = fltarr(nt) - 999. ; in km/s
  rate_boresight_object_SP = fltarr(nt) - 999. ; in km/s
  
  body_AP_angle = fltarr(nt)
  body_SP_angle = fltarr(nt)
  
  time_array_et2 = []
  for j = 0,n_elements(time_array_et)-1 do time_array_et2 = [time_array_et2, time_array_et[j]-0.1, time_array_et[j], time_array_et[j]+0.1]
  
  cspice_spkezr, object, time_array_et, boresight_frame_AP, 'CN+S', 'EUROPAM', starg, ltime
  starg_norm = starg[0:2,*] / rebin(sqrt(starg[0,*]^2 + starg[1,*]^2 + starg[2,*]^2), 3, n_elements(time_array_et))
  body_AP_angle = reform( acos(starg_norm[0,*] * boresight_AP[0] + starg_norm[1,*] * boresight_AP[1] + starg_norm[2,*] * boresight_AP[2]) / !Dtor)
  
  cspice_spkezr, object, time_array_et, boresight_frame_SP, 'CN+S', 'EUROPAM', starg, ltime
  starg_norm = starg[0:2,*] / rebin(sqrt(starg[0,*]^2 + starg[1,*]^2 + starg[2,*]^2), 3, n_elements(time_array_et))
  body_SP_angle = reform( acos(starg_norm[0,*] * boresight_SP[0] + starg_norm[1,*] * boresight_SP[1] + starg_norm[2,*] * boresight_SP[2]) / !Dtor)
  
  for i =0,nt-1 do begin
    cspice_sincpt, 'Ellipsoid', object, time_array_et[i], 'IAU_'+object, 'CN+S', 'EUROPAM', boresight_frame_AP, boresight_AP, point, trgepc, srfvec, found
    AP_found_object[i] = found
    if found eq 1 then begin
      cspice_reclat, srfvec[0:2], radius, moon_lon, moon_lat
      lat_boresight_AP_object[i]=moon_lat/!dtor
      moon_lon=moon_lon/!dtor
      convert_s3_lon_vec, moon_lon
      lon_boresight_AP_object[i]=moon_lon
    endif
    
    cspice_sincpt, 'Ellipsoid', object, time_array_et[i], 'IAU_'+object, 'CN+S', 'EUROPAM', boresight_frame_SP, boresight_SP, point, trgepc, srfvec, found
    SP_found_object[i] = found
    if found eq 1 then begin
      cspice_reclat, srfvec[0:2], radius, moon_lon, moon_lat
      lat_boresight_SP_object[i]=moon_lat/!dtor
      moon_lon=moon_lon/!dtor
      convert_s3_lon_vec, moon_lon
      lon_boresight_SP_object[i]=moon_lon
    endif
  endfor
  
  ind_loc = value_locate(time_array_et2, time_array_et)
  
  ind = where(AP_found_object eq 1, /null)
  for j = 0,n_elements(ind)-1 do begin
    tm = time_array_et2[ind_loc[ind[j]]-1]
    tp = time_array_et2[ind_loc[ind[j]]+1]
    cspice_sincpt, 'Ellipsoid', object, tm, 'IAU_'+object, 'CN+S', 'EUROPAM', boresight_frame_AP, boresight_AP, point_m, trgepc, srfvec_m, found_m
    cspice_sincpt, 'Ellipsoid', object, tp, 'IAU_'+object, 'CN+S', 'EUROPAM', boresight_frame_AP, boresight_AP, point_p, trgepc, srfvec_p, found_p
    
    if found_m eq 0 or found_p eq 0 then begin
      rate_boresight_object_AP[ind[j]] = -999.
    endif else begin
      
      if found_m eq 1 then begin
        cspice_reclat, srfvec_m[0:2], radius, moon_lon, moon_lat
        lat_boresight_AP_m=moon_lat/!dtor
        moon_lon=moon_lon/!dtor
        convert_s3_lon_vec, moon_lon
        lon_boresight_AP_m = moon_lon
      endif
      if found_p eq 1 then begin
        cspice_reclat, srfvec_p[0:2], radius, moon_lon, moon_lat
        lat_boresight_AP_p=moon_lat/!dtor
        moon_lon=moon_lon/!dtor
        convert_s3_lon_vec, moon_lon
        lon_boresight_AP_p = moon_lon
      endif
      dist_to_pt_sphere, dist_pt, mean_radius, lon_boresight_AP_p, lat_boresight_AP_p, lon_boresight_AP_m, lat_boresight_AP_m
      rate_boresight_object_AP[ind[j]] = dist_pt/(tp - tm)
    endelse

  endfor

  
  ind = where(SP_found_object eq 1, /null)
  for j = 0,n_elements(ind)-1 do begin
    tm = time_array_et2[ind_loc[ind[j]]-1]
    tp = time_array_et2[ind_loc[ind[j]]+1]
    cspice_sincpt, 'Ellipsoid', object, tm, 'IAU_'+object, 'CN+S', 'EUROPAM', boresight_frame_SP, boresight_SP, point_m, trgepc, srfvec_m, found_m
    cspice_sincpt, 'Ellipsoid', object, tp, 'IAU_'+object, 'CN+S', 'EUROPAM', boresight_frame_SP, boresight_SP, point_p, trgepc, srfvec_p, found_p

    if found_m eq 0 or found_p eq 0 then begin
      rate_boresight_object_SP[ind[j]] = -999.
    endif else begin

      if found_m eq 1 then begin
        cspice_reclat, srfvec_m[0:2], radius, moon_lon, moon_lat
        lat_boresight_SP_m=moon_lat/!dtor
        moon_lon=moon_lon/!dtor
        convert_s3_lon_vec, moon_lon
        lon_boresight_SP_m = moon_lon
      endif
      if found_p eq 1 then begin
        cspice_reclat, srfvec_p[0:2], radius, moon_lon, moon_lat
        lat_boresight_SP_p=moon_lat/!dtor
        moon_lon=moon_lon/!dtor
        convert_s3_lon_vec, moon_lon
        lon_boresight_SP_p = moon_lon
      endif
      dist_to_pt_sphere, dist_pt, mean_radius, lon_boresight_SP_p, lat_boresight_SP_p, lon_boresight_SP_m, lat_boresight_SP_m
      rate_boresight_object_SP[ind[j]] = dist_pt/(tp - tm)
    endelse
  endfor
  
  
  
;  if nt le 3 then begin
;    time_array_et2 = []
;    for j = 0,n_elements(time_array_et)-1 do time_array_et2 = [time_array_et2, time_array_et[j]-0.5, time_array_et[j]+0.5]
;
;    nt2 = n_elements(time_array_et2)
;    lat_boresight_AP_object2 = fltarr(nt2) -999.
;    lon_boresight_AP_object2 = fltarr(nt2) -999.
;    lat_boresight_SP_object2 = fltarr(nt2) -999.
;    lon_boresight_SP_object2 = fltarr(nt2) -999.
;    AP_found_object2 = intarr(nt2)
;    SP_found_object2 = intarr(nt2)
;    rate_boresight_object_AP2 = fltarr(nt2) - 999. ; in km/s
;    rate_boresight_object_SP2 = fltarr(nt2) - 999. ; in km/s
;    
;    for i =0,nt2-1 do begin
;      cspice_sincpt, 'Ellipsoid', object, time_array_et2[i], 'IAU_'+object, 'CN+S', 'EUROPAM', boresight_frame_AP, boresight_AP, point, trgepc, srfvec, found
;      AP_found_object2[i] = found
;      if found eq 1 then begin
;        cspice_reclat, srfvec[0:2], radius, moon_lon, moon_lat
;        lat_boresight_AP_object2[i]=moon_lat/!dtor
;        moon_lon=moon_lon/!dtor
;        convert_s3_lon_vec, moon_lon
;        lon_boresight_AP_object2[i]=moon_lon
;      endif
;
;      cspice_sincpt, 'Ellipsoid', object, time_array_et2[i], 'IAU_'+object, 'CN+S', 'EUROPAM', boresight_frame_SP, boresight_SP, point, trgepc, srfvec, found
;      SP_found_object2[i] = found
;      if found eq 1 then begin
;        cspice_reclat, srfvec[0:2], radius, moon_lon, moon_lat
;        lat_boresight_SP_object2[i]=moon_lat/!dtor
;        moon_lon=moon_lon/!dtor
;        convert_s3_lon_vec, moon_lon
;        lon_boresight_SP_object2[i]=moon_lon
;      endif
;    endfor
;
;    if total(AP_found_object2) ge 2 then begin
;    ind = where(AP_found_object2 eq 1, /null)
;      for j = 0,n_elements(ind)-2 do begin
;        dist_to_pt_sphere, dist_pt, mean_radius, lon_boresight_AP_object2[ind[j]], lat_boresight_AP_object2[ind[j]], lon_boresight_AP_object2[ind[j]+1], lat_boresight_AP_object2[ind[j]+1]
;        rate_boresight_object_AP2[ind[j]] = dist_pt/(time_array_et2[ind[j]+1] - time_array_et2[ind[j]])
;      endfor
;    endif
;
;    if total(SP_found_object2) ge 2 then begin
;      ind = where(SP_found_object2 eq 1, /null)
;      for j = 0,n_elements(ind)-2 do begin
;        dist_to_pt_sphere, dist_pt, mean_radius, lon_boresight_SP_object2[ind[j]], lat_boresight_SP_object2[ind[j]], lon_boresight_SP_object2[ind[j]+1], lat_boresight_SP_object2[ind[j]+1]
;        rate_boresight_object_SP2[ind[j]] = dist_pt/(time_array_et2[ind[j]+1] - time_array_et2[ind[j]])
;      endfor
;    endif
;   
;    ind_loc = value_locate(time_array_et2, time_array_et)
;    rate_boresight_object_AP = rate_boresight_object_AP2[ind_loc]
;    rate_boresight_object_SP = rate_boresight_object_SP2[ind_loc]
;  endif 
;  
;  for i =0,nt-1 do begin
;    cspice_sincpt, 'Ellipsoid', object, time_array_et[i], 'IAU_'+object, 'CN+S', 'EUROPAM', boresight_frame_AP, boresight_AP, point, trgepc, srfvec, found
;    AP_found_object[i] = found
;    if found eq 1 then begin
;      cspice_reclat, srfvec[0:2], radius, moon_lon, moon_lat
;      lat_boresight_AP_object2[i]=moon_lat/!dtor
;      moon_lon=moon_lon/!dtor
;      convert_s3_lon_vec, moon_lon
;      lon_boresight_AP_object2[i]=moon_lon
;    endif
;
;    cspice_sincpt, 'Ellipsoid', object, time_array_et2[i], 'IAU_'+object, 'CN+S', 'EUROPAM', boresight_frame_SP, boresight_SP, point, trgepc, srfvec, found
;    SP_found_object2[i] = found
;    if found eq 1 then begin
;      cspice_reclat, srfvec[0:2], radius, moon_lon, moon_lat
;      lat_boresight_SP_object2[i]=moon_lat/!dtor
;      moon_lon=moon_lon/!dtor
;      convert_s3_lon_vec, moon_lon
;      lon_boresight_SP_object2[i]=moon_lon
;    endif
;  endfor
;  
;  if nt gt 3 then begin
;    for i =0,nt-1 do begin
;      cspice_sincpt, 'Ellipsoid', object, time_array_et[i], 'IAU_'+object, 'CN+S', 'EUROPAM', boresight_frame_AP, boresight_AP, point, trgepc, srfvec, found
;      AP_found_object[i] = found
;      if found eq 1 then begin
;        cspice_reclat, srfvec[0:2], radius, moon_lon, moon_lat
;        lat_boresight_AP_object[i]=moon_lat/!dtor
;        moon_lon=moon_lon/!dtor
;        convert_s3_lon_vec, moon_lon
;        lon_boresight_AP_object[i]=moon_lon
;      endif
;
;      cspice_sincpt, 'Ellipsoid', object, time_array_et[i], 'IAU_'+object, 'CN+S', 'EUROPAM', boresight_frame_SP, boresight_SP, point, trgepc, srfvec, found
;      SP_found_object[i] = found
;      if found eq 1 then begin
;        cspice_reclat, srfvec[0:2], radius, moon_lon, moon_lat
;        lat_boresight_SP_object[i]=moon_lat/!dtor
;        moon_lon=moon_lon/!dtor
;        convert_s3_lon_vec, moon_lon
;        lon_boresight_SP_object[i]=moon_lon
;      endif
;    endfor
;
;    if total(AP_found_object) ne 0 then begin
;      AP_convol = convol(AP_found_object, [1,1,1], /edge_zero)
;      ind3 = where(AP_convol eq 3, /null)
;      for j = 0,n_elements(ind3)-1 do begin
;        dist_to_pt_sphere, dist_pt, mean_radius, lon_boresight_AP_object[ind3[j]-1], lat_boresight_AP_object[ind3[j]-1], lon_boresight_AP_object[ind3[j]+1], lat_boresight_AP_object[ind3[j]+1]
;        rate_boresight_object_AP[ind3[j]] = dist_pt/(time_array_et[ind3[j]+1] - time_array_et[ind3[j]-1])
;      endfor
;    endif
;
;    if total(SP_found_object) ne 0 then begin
;      SP_convol = convol(SP_found_object, [1,1,1], /edge_zero)
;      ind3 = where(SP_convol eq 3, /null)
;      for j = 0,n_elements(ind3)-1 do begin
;        dist_to_pt_sphere, dist_pt, mean_radius, lon_boresight_SP_object[ind3[j]-1], lat_boresight_SP_object[ind3[j]-1], lon_boresight_SP_object[ind3[j]+1], lat_boresight_SP_object[ind3[j]+1]
;        rate_boresight_object_SP[ind3[j]] = dist_pt/(time_array_et[ind3[j]+1] - time_array_et[ind3[j]-1])
;      endfor
;    endif
;  endif

end