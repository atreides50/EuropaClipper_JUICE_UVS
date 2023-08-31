pro dist_to_pt_sphere, dist_circ, radius_sphere, lon_array, lat_array, pt_lon, pt_lat
; Calculate the distance in km on a sphere of radius "radius_sphere" 
; between the sets of point with lon/lat "lon_array, lat_array"
; and a single point located on "pt_lon, pt_lat"
; 
; all lat/lon are provided/given in degrees
; 
; Vincent Hue, SwRI, 2022

dist_circ = radius_sphere * acos( sin(lat_array*!Dtor) * sin(pt_lat*!Dtor) + cos(lat_array*!Dtor) * cos(pt_lat*!Dtor) * cos( abs(lon_array - pt_lon)*!Dtor) )
dist_circ[where(finite(dist_circ, /nan) eq 1., /null)] = 0.

end