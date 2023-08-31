pro calculate_solar_eclipse_jupiter, body, time_array_et, eclipse

  eclipse = intarr(n_elements(time_array_et))
  
  for i = 0,n_elements(time_array_et)-1 do begin
    step    = 10.
    occtyp  = 'any'
    front   = 'Jupiter'
    fshape  = 'ellipsoid'
    fframe  = 'IAU_JUPITER'
    back    = 'SUN'
    bshape  = 'ellipsoid'
    bframe  = 'IAU_SUN'
    obsrvr  = body
    abcorr  = 'lt'

    MAXWIN  =  1000;
    ;cnfine = cspice_wninsd( time_array_et[0], time_array_et[0] );
    cnfine = cspice_celld(2)
    cspice_wninsd, time_array_et[i], time_array_et[i], cnfine
    result = cspice_celld(2)

    cspice_gfoclt, occtyp, front,  fshape, fframe, back, bshape, bframe, abcorr, obsrvr, step, cnfine, result
  
    eclipse[i] = cspice_wncard( result)
    
    
    ;print, time_array_utc[i], cspice_wncard( result)
    ;a = cspice_wncard( result)

  endfor

 
 
 
 
 end