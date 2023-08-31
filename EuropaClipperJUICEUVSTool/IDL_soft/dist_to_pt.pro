pro dist_to_pt, dist_circ, lon_fit, lat_fit, pt_lon, pt_lat


for ilat=0,n_elements(lat_fit)-1 do begin

  dist_circ[*,ilat] = acos( sin(lat_fit[ilat]*!Dtor) * sin(pt_lat*!Dtor) + cos(lat_fit[ilat]*!Dtor) * cos(pt_lat*!Dtor) * cos( abs(lon_fit[*] - pt_lon)*!Dtor)) / !Dtor
  
endfor



end