pro dist_to_pt2, dist_circ, lon_fit, lat_fit, pt_lon, pt_lat

nx = n_elements(lat_fit[*,0])
ny = n_elements(lat_fit[0,*])
  
for iy=0,ny-1 do begin
  dist_circ[*,iy] = acos( sin(lat_fit[*,iy]*!Dtor) * sin(pt_lat*!Dtor) + cos(lat_fit[*,iy]*!Dtor) * cos(pt_lat*!Dtor) * cos( abs(lon_fit[*,iy] - pt_lon)*!Dtor)) / !Dtor
endfor


end