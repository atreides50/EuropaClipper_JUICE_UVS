pro calculate_FOV_sky, spacecraft, spacecraft_id, time_array_et, RA_AP, DEC_AP, RA_SP, DEC_SP, rate_boresight_sky_AP, rate_boresight_sky_SP
; This routine calculates the rate of the FOV drift on the sky
; in degrees/second
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

cspice_bodn2c, boresight_frame_AP, ID_AP, found_ID
cspice_bodn2c, boresight_frame_SP, ID_SP, found_ID

; Define the size of the boundary vectors
ROOM=100
cspice_getfov, ID_AP, ROOM, shape, iframe_uvs, boresight_AP, bundry_AP
cspice_getfov, ID_AP, ROOM, shape, iframe_uvs, boresight_SP, bundry_SP

; Calculate the rate of the FOV drift on the sky for the AP
cspice_pxform, boresight_frame_AP, 'J2000', time_array_et, matrix_uvs_AP_to_J2000
boresight_AP_J2000 = fltarr(3,nt)

boresight_AP_J2000[0,*] = matrix_uvs_AP_to_J2000[0,0,0] * boresight_AP[0] +$
                          matrix_uvs_AP_to_J2000[1,0,0] * boresight_AP[1] +$
                          matrix_uvs_AP_to_J2000[2,0,0] * boresight_AP[2]

boresight_AP_J2000[1,*] = matrix_uvs_AP_to_J2000[0,1,0] * boresight_AP[0] +$
                          matrix_uvs_AP_to_J2000[1,1,0] * boresight_AP[1] +$
                          matrix_uvs_AP_to_J2000[2,1,0] * boresight_AP[2]

boresight_AP_J2000[2,*] = matrix_uvs_AP_to_J2000[0,2,0] * boresight_AP[0] +$
                          matrix_uvs_AP_to_J2000[1,2,0] * boresight_AP[1] +$
                          matrix_uvs_AP_to_J2000[2,2,0] * boresight_AP[2]

cspice_reclat, boresight_AP_J2000, boresight_AP_radius, RA_boresight_AP, DEC_boresight_AP
RA_boresight_AP /= !Dtor
DEC_boresight_AP /= !Dtor
RA_AP = RA_boresight_AP
DEC_AP = DEC_boresight_AP

for i = 1,nt-2 do begin
    dist_to_pt_sphere, dist_pt, 1, RA_boresight_AP[i-1], DEC_boresight_AP[i-1], RA_boresight_AP[i+1], DEC_boresight_AP[i+1]
    rate_boresight_sky_AP[i] = dist_pt / !Dtor / (time_array_et[i+1] - time_array_et[i-1])
endfor

; Now treating the special cases for i=0 and i = nt-1
dist_to_pt_sphere, dist_pt, 1, RA_boresight_AP[0], DEC_boresight_AP[0], RA_boresight_AP[1], DEC_boresight_AP[1]
rate_boresight_sky_AP[0] = dist_pt / !Dtor / (time_array_et[1] - time_array_et[0])
dist_to_pt_sphere, dist_pt, 1, RA_boresight_AP[nt-1], DEC_boresight_AP[nt-1], RA_boresight_AP[nt-2], DEC_boresight_AP[nt-2]
rate_boresight_sky_AP[nt-1] = dist_pt / !Dtor / (time_array_et[nt-1] - time_array_et[nt-2])


; Do the same thing for the SP
cspice_pxform, boresight_frame_SP, 'J2000', time_array_et, matrix_uvs_SP_to_J2000
boresight_SP_J2000 = fltarr(3,nt)

boresight_SP_J2000[0,*] = matrix_uvs_SP_to_J2000[0,0,0] * boresight_AP[0] +$
                          matrix_uvs_SP_to_J2000[1,0,0] * boresight_AP[1] +$
                          matrix_uvs_SP_to_J2000[2,0,0] * boresight_AP[2]

boresight_SP_J2000[1,*] = matrix_uvs_SP_to_J2000[0,1,0] * boresight_AP[0] +$
                          matrix_uvs_SP_to_J2000[1,1,0] * boresight_AP[1] +$
                          matrix_uvs_SP_to_J2000[2,1,0] * boresight_AP[2]

boresight_SP_J2000[2,*] = matrix_uvs_SP_to_J2000[0,2,0] * boresight_AP[0] +$
                          matrix_uvs_SP_to_J2000[1,2,0] * boresight_AP[1] +$
                          matrix_uvs_SP_to_J2000[2,2,0] * boresight_AP[2]

cspice_reclat, boresight_SP_J2000, boresight_SP_radius, RA_boresight_SP, DEC_boresight_SP
RA_boresight_SP /= !Dtor
DEC_boresight_SP /= !Dtor
RA_AP = RA_boresight_SP
DEC_AP = DEC_boresight_SP

for i = 1,nt-2 do begin
  dist_to_pt_sphere, dist_pt, 1, RA_boresight_SP[i-1], DEC_boresight_SP[i-1], RA_boresight_SP[i+1], DEC_boresight_SP[i+1]
  rate_boresight_sky_SP[i] = dist_pt / !Dtor / (time_array_et[i+1] - time_array_et[i-1])
endfor

; Now treating the special cases for i=0 and i = nt-1
dist_to_pt_sphere, dist_pt, 1, RA_boresight_SP[0], DEC_boresight_SP[0], RA_boresight_SP[1], DEC_boresight_SP[1]
rate_boresight_sky_SP[0] = dist_pt / !Dtor / (time_array_et[1] - time_array_et[0])
dist_to_pt_sphere, dist_pt, 1, RA_boresight_SP[nt-1], DEC_boresight_SP[nt-1], RA_boresight_SP[nt-2], DEC_boresight_SP[nt-2]
rate_boresight_sky_SP[nt-1] = dist_pt / !Dtor / (time_array_et[nt-1] - time_array_et[nt-2])





;    cspice_sincpt, 'Ellipsoid', 'JUPITER', time_array_et[i], 'IAU_JUPITER', 'CN+S', 'EUROPAM', boresight_frame_AP, boresight_AP, point, trgepc, srfvec, AP_found_jup
;    if AP_found_jup eq 1 then begin
;      cspice_reclat, srfvec[0:2], radius, jup_lon, jup_lat
;      lat_boresight_AP_jup[i]=jup_lat/!dtor
;      jup_lon=jup_lon/!dtor
;      convert_s3_lon_vec, jup_lon
;      lon_boresight_AP_jup[i]=jup_lon
;    endif



end


