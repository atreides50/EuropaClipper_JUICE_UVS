pro calculate_pixel_object, spacecraft, spacecraft_id, time_array_et, nx, object, lat_boresight_AP_object, lon_boresight_AP_object, lat_boresight_SP_object, lon_boresight_SP_object,$
                            rate_boresight_object_AP, rate_boresight_object_SP, Europa_AP_angle, Europa_SP_angle, $
                            lat_pixel_AP, lon_pixel_AP, pixel_incidence_angle_AP, pixel_emission_angle_AP, pixel_phase_angle_AP, dist_pixel_AP, $
                            lat_pixel_SP, lon_pixel_SP, pixel_incidence_angle_SP, pixel_emission_angle_SP, pixel_phase_angle_SP, dist_pixel_SP
                            

; This routine calculates if the UVS AP or SP intersect with a given object (Jupiter, moon)
; and if so, it calculates the rate of the FOV drift on the object
; in km/second
;
; Vincent Hue, SwRI, 2022

nt = n_elements(time_array_et)

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
cspice_getfov, ID_SP, ROOM, shape, iframe_uvs, boresight_SP, bundry_SP

;nx = 1009 ; Per Rohini's email on June 13 2022
x_pixelist_AP = interpol([min(bundry_AP[0,*]),max(bundry_AP[0,*])], nx)
y_pixelist_AP = fltarr(nx)
z_pixelist_AP = interpol(bundry_AP[2,*], nx)


;nx = n_elements(bundry_AP[2,*])
;x_pixelist_AP = reform(bundry_AP[0,*])
;y_pixelist_AP = reform(bundry_AP[1,*])
;z_pixelist_AP = reform(bundry_AP[2,*])



pixelist_AP = transpose([[x_pixelist_AP], [y_pixelist_AP], [z_pixelist_AP]])
;pixelist_AP = bundry_AP
;thet = acos(pixelist_AP[0,0]*pixelist_AP[0,-1] + pixelist_AP[1,0]*pixelist_AP[1,-1] + pixelist_AP[2,0]*pixelist_AP[2,-1])/!Dtor


;cgplot, asin(bundry_AP[0,*])/!Dtor, asin(bundry_AP[1,*])/!Dtor,xr=[-4.5,4.5], yr=[-4.5,4.5]


lat_pixel_AP = fltarr(nx, nt) - 999.
lon_pixel_AP = fltarr(nx, nt) - 999.
dist_pixel_AP = dblarr(nx, nt) - 999.
dist_pixel_SP = dblarr(nx, nt) - 999.
pixel_incidence_angle_AP = fltarr(nx, nt) - 999.
pixel_emission_angle_AP = fltarr(nx, nt) - 999.
pixel_phase_angle_AP =  fltarr(nx, nt) - 999.

x_pixelist_SP = interpol([min(bundry_SP[0,*]),max(bundry_SP[0,*])], nx)
y_pixelist_SP = fltarr(nx)
z_pixelist_SP = interpol(bundry_SP[2,*], nx)
pixelist_SP = transpose([[x_pixelist_SP], [y_pixelist_SP], [z_pixelist_SP]])
;pixelist_SP = bundry_SP

lat_pixel_SP = fltarr(nx, nt) - 999.
lon_pixel_SP = fltarr(nx, nt) - 999.
pixel_incidence_angle_SP = fltarr(nx, nt) - 999.
pixel_emission_angle_SP = fltarr(nx, nt) - 999.
pixel_phase_angle_SP =  fltarr(nx, nt) - 999.

; cspice_spkezr, targ, et, ref, abcorr, obs, starg, ltime

cspice_spkezr, 'Sun', time_array_et, 'IAU_'+object, 'CN+S', object, object_to_sun, ltime
cspice_spkezr, spacecraft, time_array_et, 'IAU_'+object, 'CN+S', object, object_to_sc, ltime

;starg_norm = starg[0:2,*] / rebin(sqrt(starg[0,*]^2 + starg[1,*]^2 + starg[2,*]^2), 3, n_elements(time_array_et))
;body_AP_angle = reform( acos(starg_norm[0,*] * boresight_AP[0] + starg_norm[1,*] * boresight_AP[1] + starg_norm[2,*] * boresight_AP[2]) / !Dtor)

for i = 0,nt-1 do begin
  for ix = 0,nx-1 do begin
    
    ; cspice_sincpt, method, target, et, fixref, abcorr, obsrvr, dref, dvec, spoint, trgepc, srfvec, found
      
    cspice_sincpt, 'Ellipsoid', object, time_array_et[i], 'IAU_'+object, 'CN+S', 'EUROPAM', boresight_frame_AP, pixelist_AP[*,ix], point, trgepc, srfvec, found
    ;cspice_sincpt, 'Ellipsoid', object, time_array_et[i], 'IAU_'+object, 'CN+S', 'EUROPAM', 'EUROPAM_UVS_SP', pixelist_AP[*,ix], point, trgepc, srfvec, found
    ;stop
    
    if found eq 1 then begin
      ;cspice_reclat, srfvec[0:2], radius, moon_lon, moon_lat
      cspice_reclat, point, radius, moon_lon, moon_lat
      lat_pixel_AP[ix, i]=moon_lat/!dtor
      moon_lon=moon_lon/!dtor
      convert_s3_lon_vec, moon_lon
      lon_pixel_AP[ix, i]=moon_lon
      point_norm = point/norm(point)
      
      point_to_sun = object_to_sun[0:2, i] - point[0:2]
      point_to_sun_norm = point_to_sun/sqrt(point_to_sun[0]^2 + point_to_sun[1]^2 + point_to_sun[2]^2)
      pixel_incidence_angle_AP[ix, i] = reform( acos(point_to_sun_norm[0] * point_norm[0] + point_to_sun_norm[1] * point_norm[1] + point_to_sun_norm[2] * point_norm[2]) / !Dtor)
            
      point_to_sc = - srfvec[0:2]
      ;point_to_sc = object_to_sc[0:2, i] - srfvec[0:2]
      dist_pixel_AP[ix, i] = sqrt(point_to_sc[0]^2 + point_to_sc[1]^2 + point_to_sc[2]^2)
      point_to_sc_norm = point_to_sc/dist_pixel_AP[ix, i]
      pixel_emission_angle_AP[ix, i] = reform( acos(point_to_sc_norm[0] * point_norm[0] + point_to_sc_norm[1] * point_norm[1] + point_to_sc_norm[2] * point_norm[2]) / !Dtor)
      
      pixel_phase_angle_AP[ix, i] = reform( acos(point_to_sc_norm[0] * point_to_sun_norm[0] + point_to_sc_norm[1] * point_to_sun_norm[1] + point_to_sc_norm[2] * point_to_sun_norm[2]) / !Dtor)
    endif
    
    cspice_sincpt, 'Ellipsoid', object, time_array_et[i], 'IAU_'+object, 'CN+S', 'EUROPAM', boresight_frame_SP, pixelist_SP[*,ix], point, trgepc, srfvec, found
    if found eq 1 then begin
      ;cspice_reclat, srfvec[0:2], radius, moon_lon, moon_lat
      cspice_reclat, point, radius, moon_lon, moon_lat
      lat_pixel_SP[ix, i]=moon_lat/!dtor
      moon_lon=moon_lon/!dtor
      convert_s3_lon_vec, moon_lon
      lon_pixel_SP[ix, i]=moon_lon
      point_norm = point/norm(point)

      point_to_sun = object_to_sun[0:2, i] - point[0:2]
      point_to_sun_norm = point_to_sun/sqrt(point_to_sun[0]^2 + point_to_sun[1]^2 + point_to_sun[2]^2)
      pixel_incidence_angle_SP[ix, i] = reform( acos(point_to_sun_norm[0] * point_norm[0] + point_to_sun_norm[1] * point_norm[1] + point_to_sun_norm[2] * point_norm[2]) / !Dtor)

      point_to_sc = - srfvec[0:2]
      dist_pixel_SP[ix, i] = sqrt(point_to_sc[0]^2 + point_to_sc[1]^2 + point_to_sc[2]^2)
      point_to_sc_norm = point_to_sc/dist_pixel_SP[ix, i]
      pixel_emission_angle_SP[ix, i] = reform( acos(point_to_sc_norm[0] * point_norm[0] + point_to_sc_norm[1] * point_norm[1] + point_to_sc_norm[2] * point_norm[2]) / !Dtor)

      pixel_phase_angle_SP[ix, i] = reform( acos(point_to_sc_norm[0] * point_to_sun_norm[0] + point_to_sc_norm[1] * point_to_sun_norm[1] + point_to_sc_norm[2] * point_to_sun_norm[2]) / !Dtor)
    endif
  endfor
  
;    dist_to_pt_sphere, dist_pt, mean_radius, lon_pixel_AP[0, i], lat_pixel_AP[0, i], lon_pixel_AP[-1, i], lat_pixel_AP[-1, i]
;    print, 'Dist: ', dist_pt, dist_pt/mean_radius/!Dtor
endfor







;lat_pixel_AP, lon_pixel_AP, pixel_incidence_angle_AP, pixel_phase_angle_AP, $
;lat_pixel_SP, lon_pixel_SP, pixel_incidence_angle_SP, pixel_phase_angle_SP
;  
;lat_pixel_AP = fltarr(nx, nt) - 999.
;lon_pixel_AP = fltarr(nx, nt) - 999.
;pixel_incidence_angle_AP = fltarr(nx, nt) - 999.
;pixel_emission_angle_AP = fltarr(nx, nt) - 999.
;
;
;lat_pixel_SP = fltarr(nx, nt) - 999.
;lon_pixel_SP = fltarr(nx, nt) - 999.
;pixel_incidence_angle_SP = fltarr(nx, nt) - 999.
;pixel_emission_angle_SP = fltarr(nx, nt) - 999.




end