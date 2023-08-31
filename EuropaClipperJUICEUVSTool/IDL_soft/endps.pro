pro endps, pv=pv

;;
;; Reset the plotting parameters
!p.thick = 1
!p.charsize=1
!p.charthick=1
!x.thick=1
!y.thick=1

;;
;; Close the device
device,/close
device,encapsulated = 0
device,preview = 0
device,/portrait
set_plot, !version.os eq 'darwin' ? 'X' : 'WIN' 
!p.font = -1  
  
end
