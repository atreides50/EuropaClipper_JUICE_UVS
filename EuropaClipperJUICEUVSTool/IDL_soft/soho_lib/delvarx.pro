PRO delvarx, p0,p1,p2,p3,p4,p5,p6,p7,p8,p9
   FOR i = 0, N_PARAMS()-1 DO BEGIN ; for each parameter
      param = STRCOMPRESS("p" + STRING(i),/remove)
;  only delete if defined on inpu (avoids error message)
      exestat = execute("defined=n_elements(" + param + ")" ) 
      IF defined GT 0 THEN BEGIN
         exestat = execute(param + "=0")
         exestat = execute("dvar=temporary(" + param + ")" )
      ENDIF
   ENDFOR
   RETURN
END
