pro plotps3, filename, pv=pv, flip=flip, quiet=quiet

;;
;; Set up all thicknesses
!p.thick = 5
!p.charsize = 1.
!p.charthick=4
!x.thick=5
!y.thick=5

;;
;; Set up dimensions
xs=8
ys=8
x0 = 0
y0 = 0
scale= 1.


;; Set scale of size
xs = scale * xs
ys = scale * ys

;; Set up ps plotting
IF ~keyword_set(quiet) THEN $
  print,'Creating sized PS image called '+strtrim(filename,2)
  set_plot,'ps'
  ;set_plot,'gif'

;;
;; Flip colors if requested
if keyword_set(flip) then begin
  !p.color = 255
  !p.background = 255
endif

;;
;; Set device
device, /inches,$
        xsize=xs,$
        xoffset=0,$
        ysize=ys,$
        yoffset=3,$
        filename=filename, $
        encapsulated = 0,$
        /helvetica,$
        decomposed=1,$
        FONT_SIZE=16
        
        
       
!p.font=0

device,/color

end
