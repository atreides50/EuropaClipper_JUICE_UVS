pro rotate_into_dipole, LON, LAT, LON2, LAT2, rotation_direction=rotation_direction

;restoreaurora_v2, '/Users/vhue/Desktop/Juno/Science/Io_FluxTube_opportunity/Input/', innerOval, outerOval, /south
;LAT = [reform(innerOval[1,*]), reform(outerOval[1,*])]
;LON = [reform(innerOval[0,*]), reform(outerOval[0,*])]
;;convert_s3_e_lon_vec, LON

; Connerney et al., 2021:
; The degree 1 coefficients of the JRM33 model describe a dipole with moment M = 4.177 G, offset from the rotation
; axis by theta_d = 10.25˚ towards System III longitude of Phi_d = 196.38˚


dipole_tilt = 10.25d0
longitude_dipole = 196.38d0

lat_dipole = 90. - dipole_tilt
lon_dipole = longitude_dipole

u0 = [0., 0., 1.]
cspice_latrec, 1., 0*!Dtor, 90*!Dtor, u0
cspice_latrec, 1., longitude_dipole*!Dtor, 0*!Dtor, u1
u2 = CROSSP(u0, u1)

cspice_reclat, u0, r0, lon_u0, lat_u0
cspice_reclat, u1, r1, lon_u1, lat_u1
cspice_reclat, u2, r2, lon_u2, lat_u2
lon_u0 /= !Dtor & lat_u0 /= !Dtor
lon_u1 /= !Dtor & lat_u1 /= !Dtor
lon_u2 /= !Dtor & lat_u2 /= !Dtor

; To place ourselves in the reference frame with +z aligned with the magnetic dipole
; one needs to rotate by dipole_tilt around u2
ux = u2[0]
uy = u2[1]
uz = u2[2]

if rotation_direction eq 'forward' then begin
  ang_rot = -dipole_tilt
endif
if rotation_direction eq 'reverse' then begin
  ang_rot = dipole_tilt
endif

c = cos(ang_rot*!Dtor)
s = sin(ang_rot*!Dtor)

m = [[c + ux^2*(1.-c),        ux*uy*(1.-c) - uz*s,     ux*uz*(1.-c) + uy*s],$
     [uy*ux*(1.-c) + uz*s,    c + uy^2*(1.-c),         uy*uz*(1.-c) - ux*s],$
     [uz*ux*(1.-c) - uy*s,    uz*uy*(1.-c) + ux*s,     c + uz^2*(1.-c)]]

cspice_srfrec, 599, LON*0., LAT*!dtor, POS ; get the radius of Jupiter at that mean latitude (uses the azimuthal symmetry of Jupiter)

RAD = reform(sqrt(POS[0,*]^2 + POS[1,*]^2 + POS[2,*]^2))
mean_rad = mean(RAD)

cspice_latrec, RAD, LON*!Dtor, LAT*!Dtor, xyz

xfp = reform(xyz[0,*])
yfp = reform(xyz[1,*])
zfp = reform(xyz[2,*])
xfp2 = xfp * 0.
yfp2 = xfp * 0.
zfp2 = xfp * 0.

for j = 0,n_elements(yfp)-1 do begin
  cspice_mxv, m, [xfp[j], yfp[j], zfp[j]], vout
  xfp2[j] = vout[0]
  yfp2[j] = vout[1]
  zfp2[j] = vout[2]
endfor

;p1 = PLOT3D([0,0], [0,0], [0,1], color='red')
;p2 = PLOT3D([0,1], [0,0], [0,0], color='red', /overplot)
;p3 = PLOT3D([0,0], [0,1], [0,0], color='red', /overplot)
;p3 = PLOT3D([0,udip[0]], [0,udip[1]], [0,udip[2]], color='blue', /overplot)
;p3 = PLOT3D([0,u0[0]], [0,u0[1]], [0,u0[2]], color='orange', /overplot)
;p3 = PLOT3D([0,u1[0]], [0,u1[1]], [0,u1[2]], color='green', /overplot)
;p3 = PLOT3D([0,u2[0]], [0,u2[1]], [0,u2[2]], color='purple', /overplot)
;p3 = PLOT3D(xfp/mean_rad, yfp/mean_rad, zfp*0., color='red', /overplot)
;p3 = PLOT3D([0,u0x], [0,u0y], [0,u0z], color='orange', /overplot)

;xfp2 = m[0,0] * xfp + m[0,1] * yfp + m[0,2] * zfp
;yfp2 = m[1,0] * xfp + m[1,1] * yfp + m[1,2] * zfp
;zfp2 = m[2,0] * xfp + m[2,1] * yfp + m[2,2] * zfp

vec = transpose([[xfp2], [yfp2], [zfp2]])

cspice_reclat, vec, RAD2, LON2, LAT2
RAD2 = LON*0. + RAD2
LAT2 = LON*0. + LAT2/!Dtor
LON2 = LON*0. + LON2/!Dtor
;convert_s3_lon_vec, LON2


;window,0,xs=900,ys=900
;device, decomposed=0
;loadct, 33
;cgmap_set,90.,180.,0.,/orthographic, xmargin=2, ymargin=2, Limit= [40., 0., 90., 360.], REVERSE=1
;;cgmap_set,-90.,180.,0.,/orthographic, xmargin=2, ymargin=2, Limit= [-90., 0., -40., 360.], REVERSE=1, position = [x0,y0,x1,y1]
;;; Set up the satellite projection:
;MAP_GRID, /LABEL, LATDEL=10., LONDEL=45., LONS=LONS, LONNAMES = LONNAMES, LONLAB=45., LATLAB=0 ,LATS=LATS, LATNAMES=LATNAMES, charsize=0.8, thick=2
;
;cgoplot, LON, LAT, psym=1, symsize=ssz, thick=sth
;;cgoplot, LON2, LAT2, psym=1, symsize=ssz, thick=sth, color=cgcolor('red')
;cgoplot, LON2[0:200], LAT2[0:200], psym=1, symsize=ssz, thick=sth, color=cgcolor('red')
;
;cgoplot, lon_dipole, lat_dipole, psym=16, symsize=ssz, thick=sth, color=cgcolor('blue')
;
;stop

end