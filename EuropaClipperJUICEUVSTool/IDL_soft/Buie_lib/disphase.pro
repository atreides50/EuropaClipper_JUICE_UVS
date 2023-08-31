;+
; NAME: 
;  disphase
; PURPOSE: 
;  Apply distance and phase angle correction to observed magnitudes.
; DESCRIPTION:
;  Apply standard asteroidal-law corrections to observed magnitudes
;     given the distance, phase angle, and the G coefficient.  Magnitudes
;     are corrected to 1 AU from Sun and Earth and to 0 degrees phase angle.
;  The default of this routine is to use equation A4 from Bowell etal. in
;     Asteroids II (see page 550) and called the Lumme and Bowell model.
;     An option is provided to compute the IAU standard correction from
;     equation A5 found on page 551.
;
;  According to the Bowell chapter, these expressions are valid only
;     for 0<=G<=1 and phase angle less than 120 degrees.  However, the
;     chapter also claims the expressions are useful outside this range.
;
;  Note that the computation blows up in single precision if G < -0.85.  If
;     the input value for G is out of range then the returned magnitude is
;     set to -99.99.  This prevents getting back a value of NaN for hmag.
; CATEGORY:
;  Photometry
; CALLING SEQUENCE:
;  disphase,mag,r,d,phang,g,hmag
; INPUTS:
;     mag   - Observed magnitude.
;     r     - Sun-object distance in AU.
;     d     - Earth-object distance in AU.
;     phang - Phase angle of observation in degrees.
;     g     - IAU standard G value (phase angle coefficient).
; OPTIONAL INPUT PARAMETERS:
; KEYWORD INPUT PARAMETERS:
;     H2MAG - Flag, if set reverses the sense of the calculations and takes
;                H as the input magnitude and then computes the apparent
;                magnitude for the output.
;     IAU   - Flag, if set will force the use of the lower accuracy IAU
;                standard calculation.  The default is to use the
;                Lumme and Bowell model.
; OUTPUTS:
;     hmag  - Magnitude corrected for distance and phase angle.
; KEYWORD OUTPUT PARAMETERS:
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
; PROCEDURE:
; MODIFICATION HISTORY:
;   2008/04/12, MWB, slight change to deal with bogus values for G
;   2016/01/06, MWB, added H2MAG keyword option
;   2016/01/13, MWB, added IAU keyword option
;-
pro disphase,mag,r,d,phang,g,hmag,H2MAG=h2mag,IAU=iau,DEBUG=debug

   ; for safety. phase angle should be positive definite but some methods
   ;   of calculation need to distinguish between pre-opposition phase
   ;   and post-opposition phase.  This routine treats both the same.
   phangr = abs(phang)/!radeg

   sphang = sin(phangr)
   tphang2= tan( phangr * 0.5 )

   if keyword_set(iau) then begin
      phi1 = exp( -3.33 * (tan(phangr/2.0)^0.63 ) )
      phi2 = exp( -1.87 * (tan(phangr/2.0)^1.22 ) )
;print,tan(phangr/2.0)
;print,tan(phangr/2.0)^0.63
;print,tan(phangr/2.0)^1.22
;print,-3.33*tan(phangr/2.0)^0.63
;print,-1.87*tan(phangr/2.0)^1.22
;print,-3.33*(tan(phangr/2.0)^0.63)
;print,-1.87*(tan(phangr/2.0)^1.22)
;print,phi1,phi2
;      phi1 = exp( -(3.33 *tan(phangr/2.0))^0.63 )
;      phi2 = exp( -(1.87 *tan(phangr/2.0))^1.22 )
;print,3.33*tan(phangr/2.0)
;print,1.87*tan(phangr/2.0)
;print,-(3.33*tan(phangr/2.0))^0.63
;print,-(1.87*tan(phangr/2.0))^1.22
;print,phi1,phi2
      if keyword_set(debug) then begin
;print,'a'
         print,'Phi1'
         print,phi1
         print,'Phi2'
         print,phi2
      endif
   endif else begin
      w = exp( -90.56 * tphang2 * tphang2 )
      t = sphang / (0.119 + 1.341*sphang - 0.754*sphang*sphang )
      phi1s = 1.0 - 0.986 * t
      phi2s = 1.0 - 0.238 * t
      phi1l = exp( -3.332*tphang2^0.631 )
      phi2l = exp( -1.862*tphang2^1.218 )

      phi1 = w*phi1s + (1.0-w)*phi1l
      phi2 = w*phi2s + (1.0-w)*phi2l
   endelse

   safe_g = g > (-0.85)

   if keyword_set(h2mag) then begin
      hmag = mag + 5.0*alog10(r*d) - 2.5*alog10( (1-safe_g)*phi1 + safe_g*phi2 )
   endif else begin
      hmag = mag - 5.0*alog10(r*d) + 2.5*alog10( (1-safe_g)*phi1 + safe_g*phi2 )
   endelse

   z=where(g ne safe_g,count)
   if count ne 0 then hmag[z] = -99.99

end

