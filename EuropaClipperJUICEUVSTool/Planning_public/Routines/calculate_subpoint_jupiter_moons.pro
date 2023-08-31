pro calculate_subpoint_jupiter_moons, spacecraft, spacecraft_id, moon, time_array_et, subsc_moon_lat, subsc_moon_lon, submoon_jupiter_lat, submoon_jupiter_lon, $
                                      subsolar_moon_lat, subsolar_moon_lon, range_sc_moon, altitude_sc_moon, local_time, eclipse_moon,$
                                      mag_lat_moon, cent_lat_moon

; Calculate the following relevant information for a given missions
; subsc_moon_lat, subsc_moon_lon
; submoon_jupiter_lat, submoon_jupiter_lon
; subsolar_moon_lat, subsolar_moon_lon
; Phase moon
; eclipse_moon
; magnetic latitude of the moon
; centifugal latitude of the moon according to the Phipps & Bagenal 2021
;
; Vincent Hue, SwRI, 2022

cspice_bodvrd, moon, "RADII", 3, radii_moon
mean_radius = mean(radii_moon)

cspice_bodn2c, moon, moon_id, found_moon
nt = n_elements(time_array_et)

; Sub-SC moon lat/lon
cspice_spkezr, spacecraft_id, time_array_et, 'IAU_'+moon, 'CN+S', moon, sc_state, ltime
cspice_reclat, sc_state[0:2,*], radius, subsc_moon_lon, subsc_moon_lat
subsc_moon_lat=subsc_moon_lat/!dtor
subsc_moon_lon_e=subsc_moon_lon/!dtor
subsc_moon_lon=subsc_moon_lon_e
convert_s3_lon_vec, subsc_moon_lon

range_sc_moon = sqrt(sc_state[0,*]^2 + sc_state[1,*]^2 + sc_state[2,*]^2)
cspice_srfrec, moon_id, subsc_moon_lon_e/!Dtor, subsc_moon_lat/!Dtor, moon_carte
rad_jup = sqrt( moon_carte[0]^2. + moon_carte[1]^2. + moon_carte[2]^2.)
altitude_sc_moon = range_sc_moon - rad_jup

; Sub-moon jupiter lat/lon
cspice_spkezr, moon, time_array_et, 'IAU_JUPITER', 'CN+S', 'JUPITER', moon_state, ltime
cspice_reclat, moon_state[0:2,*], radius, submoon_jupiter_lon, submoon_jupiter_lat
submoon_jupiter_lat=submoon_jupiter_lat/!dtor
submoon_jupiter_lon=submoon_jupiter_lon/!dtor
convert_s3_lon_vec, submoon_jupiter_lon

calculate_mag_cent_latitudes_from_s3wlon, submoon_jupiter_lon, submoon_jupiter_lat, mag_lat_moon, cent_lat_moon

; Sub-solar moon lat/lon
cspice_spkezr, 'Sun', time_array_et, 'IAU_'+moon, 'CN+S', moon, sun_state, ltime
cspice_reclat, sun_state[0:2,*], radius, subsolar_moon_lon, subsolar_moon_lat
subsolar_moon_lat=subsolar_moon_lat/!dtor
subsolar_moon_lon=subsolar_moon_lon/!dtor
convert_s3_lon_vec, subsolar_moon_lon

; Sub-moon jupiter lat/lon
cspice_spkezr, 'Sun', time_array_et, 'IAU_JUPITER', 'CN+S', 'JUPITER', sun_state2, ltime
cspice_reclat, sun_state2[0:2,*], radius, lon_sun, lat_sun
lat_sun=lat_sun/!dtor
lon_sun=lon_sun/!dtor
convert_s3_lon_vec, lon_sun

ang = submoon_jupiter_lon*0.
ind1 = where(submoon_jupiter_lon ge lon_sun, /null, complement=ind0)
if ind1 ne !null then ang[ind1] = lon_sun[ind1] + 360.- submoon_jupiter_lon[ind1]
if ind0 ne !null then ang[ind0] = lon_sun[ind0] - submoon_jupiter_lon[ind0]

local_time = (ang * 24. / 360. + 12) mod 24

calculate_solar_eclipse_jupiter, moon, time_array_et, eclipse_moon

;CASE 1 OF
;  spacecraft eq 'Europa': begin
;    boresight_frame_AP = 'EUROPAM_UVS_AP'
;    boresight_frame_SP = 'EUROPAM_UVS_SP'
;    end
;  spacecraft eq 'JUICE': begin
;    boresight_frame_AP = 'JUICE_UVS_AP'
;    boresight_frame_SP = 'JUICE_UVS_SP'
;    end
;end 
;
;cspice_bodn2c, boresight_frame_AP, ID_AP, found_ID
;cspice_bodn2c, boresight_frame_SP, ID_SP, found_ID
;
;; Define the size of the boundary vectors
;ROOM=100
;cspice_getfov, ID_AP, ROOM, shape, iframe_uvs, boresight_AP, bundry_AP
;cspice_getfov, ID_AP, ROOM, shape, iframe_uvs, boresight_SP, bundry_SP
;
;;print , '####################'
;;print , moon
;;print , '####################'
;
;lat_boresight_AP_moon = fltarr(nt) -999.
;lon_boresight_AP_moon = fltarr(nt) -999.
;lat_boresight_SP_moon = fltarr(nt) -999.
;lon_boresight_SP_moon = fltarr(nt) -999.
;AP_found_moon = intarr(nt)
;SP_found_moon = intarr(nt)
;
;for i =0,nt-1 do begin
;  cspice_sincpt, 'Ellipsoid', moon, time_array_et[i], 'IAU_'+moon, 'CN+S', 'EUROPAM', boresight_frame_AP, boresight_AP, point, trgepc, srfvec, found
;  AP_found_moon[i] = found
;  if found eq 1 then begin
;    cspice_reclat, srfvec[0:2], radius, moon_lon, moon_lat
;    lat_boresight_AP_moon[i]=moon_lat/!dtor
;    moon_lon=moon_lon/!dtor
;    convert_s3_lon_vec, moon_lon
;    lon_boresight_AP_moon[i]=moon_lon
;  endif
;  
;  cspice_sincpt, 'Ellipsoid', moon, time_array_et[i], 'IAU_'+moon, 'CN+S', 'EUROPAM', boresight_frame_SP, boresight_SP, point, trgepc, srfvec, found
;  SP_found_moon[i] = found
;  if found eq 1 then begin
;    cspice_reclat, srfvec[0:2], radius, moon_lon, moon_lat
;    lat_boresight_SP_moon[i]=moon_lat/!dtor
;    moon_lon=moon_lon/!dtor
;    convert_s3_lon_vec, moon_lon
;    lon_boresight_SP_moon[i]=moon_lon
;  endif  
;endfor
;
;rate_boresight_moon_AP = fltarr(nt) - 999. ; in km/s
;rate_boresight_moon_SP = fltarr(nt) - 999. ; in km/s
;
;if total(AP_found_moon) ne 0 then begin
;  AP_convol = convol(AP_found_moon, [1,1,1], /edge_zero)
;  ind3 = where(AP_convol eq 3, /null)
;  for j = 0,n_elements(ind3)-1 do begin
;     dist_to_pt_sphere, dist_pt, mean_radius, lon_boresight_AP_moon[ind3[j]-1], lat_boresight_AP_moon[ind3[j]-1], lon_boresight_AP_moon[ind3[j]+1], lat_boresight_AP_moon[ind3[j]+1]
;     rate_boresight_moon_AP[ind3[j]] = dist_pt/(time_array_et[ind3[j]+1] - time_array_et[ind3[j]-1])
;  endfor
;endif
;
;if total(SP_found_moon) ne 0 then begin
;  SP_convol = convol(SP_found_moon, [1,1,1], /edge_zero)
;  ind3 = where(SP_convol eq 3, /null)
;  for j = 0,n_elements(ind3)-1 do begin
;    dist_to_pt_sphere, dist_pt, mean_radius, lon_boresight_SP_moon[ind3[j]-1], lat_boresight_SP_moon[ind3[j]-1], lon_boresight_SP_moon[ind3[j]+1], lat_boresight_SP_moon[ind3[j]+1]
;    rate_boresight_moon_SP[ind3[j]] = dist_pt/(time_array_et[ind3[j]+1] - time_array_et[ind3[j]-1])
;  endfor
;endif

end