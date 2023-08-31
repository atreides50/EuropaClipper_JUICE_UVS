pro compute_ang_size, spacecraft_id, time_array_et, ang_diameter, body
; This routine compute the angular diameter of a given body (e.g., Jupiter, Io, Ganymede), 
; as seen by a given spacecraft (Europa, JUICE)
; 
; The kernels need to be previously loaded
; The spacecraft ID need to be pass as input
;
; Vincent Hue, SwRI, 2022

  ;; Get the radii of Jupiter.
  cspice_bodvrd, body, 'RADII', 3, radii
  cspice_spkezr,spacecraft_id, time_array_et,'IAU_'+body,'LT+S', body ,scstat,ltime
  ang_diameter = time_array_et*0.
  
  scpos = scstat[0:2,*]
  for i =0,n_elements(time_array_et)-1 do begin
    cspice_edlimb, radii[0], radii[1], radii[2], scpos[0:2,i], limb
    cspice_el2cgv, limb, center, smajor, sminor
    d = scpos[0:2,i] - center * cspice_vdot( scpos[0:2,i]/norm(scpos[0:2,i]), center/norm(center))
    ang_diameter[i] = 2.*atan(cspice_vnorm(smajor)/norm(d))/cspice_rpd()
  endfor
  
end

