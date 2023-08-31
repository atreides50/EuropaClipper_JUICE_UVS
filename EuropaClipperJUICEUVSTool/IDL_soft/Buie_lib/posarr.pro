;+
; NAME:
;  posarr
; PURPOSE:   (one line only)
;  Generate array of positions that match an image
; DESCRIPTION:
; CATEGORY:
;  Miscellaneous
; CALLING SEQUENCE:
;  posarr,nx,ny,xarr,yarr
; INPUTS:
;  nx - width of array
;  ny - height of array
; OPTIONAL INPUT PARAMETERS:
; KEYWORD INPUT PARAMETERS:
;  X0 - location of the X origin in the image, default=0
;  Y0 - location of the Y origin in th eimage, default=0
;  SCALE - scale factor of image pixel to your desired x,y scale,
;             default=1.0
; OUTPUTS:
;  xarr - Array with the x position of each pixel in the array value
;  yarr - Array with the y position
; KEYWORD OUTPUT PARAMETERS:
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
; PROCEDURE:
; MODIFICATION HISTORY:
;  2016/09/23, Written by Marc W. Buie, Southwest Research Institute
;-
pro posarr,nx,ny,xarr,yarr,X0=x0,Y0=y0,SCALE=scale

   self='posarr: '
   if badpar(nx,[2,3],0,caller=self+'(nx) ') then return
   if badpar(ny,[2,3],0,caller=self+'(ny) ') then return
   if badpar(ny,[2,3],0,caller=self+'(ny) ') then return

   if badpar(x0,[0,2,3,4,5],0,caller=self+'(X0) ',default=0) then return
   if badpar(y0,[0,2,3,4,5],0,caller=self+'(Y0) ',default=0) then return
   if badpar(scale,[0,2,3,4,5],0,caller=self+'(SCALE) ',default=1) then return

   x = indgen(nx)
   oney = replicate(1,ny)
   xarr = x#oney

   y = indgen(ny)
   onex = replicate(1,nx)
   yarr = onex#y

   ; avoid returning float in the full default case
   if x0 eq 0 and y0 eq 0 and scale eq 1 then return

   xarr = (xarr-x0)*scale
   yarr = (yarr-y0)*scale

end
