pro dist_to_pt_stars, dist_circ, ra_stars, dec_stars, pt_ra, pt_dec


;temp = 
;temp[where(temp eq 1., /null)] = 0.99999d0

dist_circ = acos( sin(dec_stars*!Dtor) * sin(pt_dec*!Dtor) + cos(dec_stars*!Dtor) * cos(pt_dec*!Dtor) * cos( abs(ra_stars - pt_ra)*!Dtor) ) / !Dtor
dist_circ[where(finite(dist_circ, /nan) eq 1., /null)] = 0.
  
  
  
return
end