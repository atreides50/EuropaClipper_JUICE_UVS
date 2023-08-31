pro plotps, filename, pv=pv, flip=flip

;;
;; Set up all thicknesses
!p.thick = 6
!p.charsize = 1.3
!p.charthick=6
!x.thick=6
!y.thick=6

;;
;; Set up dimensions
xs=11
ys=8.5
x0 = 0
y0 = 10.5
scale= .95

;;
;; Set scale of size
xs = scale * xs
ys = scale * ys

;;
;; Set up ps plotting
IF ~keyword_set(quiet) THEN $
  print,'Creating sized PS image called '+strtrim(filename,2)
set_plot,'ps'

;;
;; Flip colors if requested
if keyword_set(flip) then begin
  !p.color = 255
  !p.background = 255
endif

;;
;; Set device
device, /landscape,$
        /inches,$
        xoffset=x0,$
        xsize=xs,$
        yoffset=y0,ysize=ys,$
        filename=filename, $
        encapsulated = 0,$
        scale_factor = scale , $
        /helvetica
       
!p.font=0

device,/color

end
