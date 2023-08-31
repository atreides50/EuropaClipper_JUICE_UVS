

FUNCTION Interpu_2d, ainp, xinp, yinp, x_new, y_new, inp_unc=inp_unc0, $
                    ux_new=ux_new, uy_new=uy_new, out_unc=out_unc

;a must be a 2d array,
   siz_a = size(ainp)
   IF(siz_a(0) NE 2) THEN BEGIN
      print, ' A MUST BE A 2-d ARRAY'
      out_unc = 0.0
      RETURN, 0.0
   ENDIF
   ipix = siz_a(1)
   jpix = siz_a(2)

;x and y have gotta have the appropriate number of elements   
   IF(N_ELEMENTS(xinp) NE ipix) OR (N_ELEMENTS(yinp) NE jpix) THEN BEGIN
      print, 'BAD SIZES FOR X OR Y ARRAY, TRY AGAIN'
      out_unc = 0.0
      RETURN, 0.0
   ENDIF

;Sort x and y, get appropriate a
   ss_x = sort(xinp)
   x = xinp(ss_x)
   ss_y = sort(yinp)
   y = yinp(ss_y)
   a = ainp(*, ss_y)
   a = a(ss_x, *)               ;wow, this is the right way to do it

   dx = x(1:ipix-1)-x(0:ipix-2) ;for the interpolation
   dy = y(1:jpix-1)-y(0:jpix-2) ;for the interpolation
   
   nx = N_ELEMENTS(x_new) & ny = N_ELEMENTS(y_new)

;Here decide if you're doing uncertainties
   qunc = 0
   IF(KEYWORD_SET(inp_unc0)) THEN BEGIN
      IF(N_ELEMENTS(inp_unc0) NE ipix*jpix) THEN $
        unci = replicate(inp_unc0(0), ipix, jpix) ELSE BEGIN
         unci = inp_unc0
         unci = unci(*, ss_y)
         unci = unci(ss_x, *)
      ENDELSE
      qunc = 1
   ENDIF ELSE unci = fltarr(ipix, jpix)

   IF(KEYWORD_SET(ux_new)) THEN BEGIN
      IF(N_ELEMENTS(ux_new) NE nx) THEN uncx = replicate(ux_new(0), nx) $
        ELSE uncx = ux_new
      qunc = 1
   ENDIF ELSE uncx = fltarr(nx)

   IF(KEYWORD_SET(uy_new)) THEN BEGIN
      IF(N_ELEMENTS(uy_new) NE ny) THEN uncy = replicate(uy_new(0), ny) $
        ELSE uncy = uy_new
      qunc = 1
   ENDIF ELSE uncy = fltarr(ny)

;ok, find the positions of the new points in the old array
   ix0 = lonarr(nx)              ;point where x is less than or equal to x_new
   FOR i = 0L, nx-1 DO ix0(i) = max(where(x_new(i) GE x))
   ix0 = ix0 > 0 & ix0 = ix0 < (ipix-2) ;limits on ix0
   ix1 = ix0+1
   
   jy0 = lonarr(ny)              ;point where y is less than or equal to y_new
   FOR i = 0L, ny-1 DO jy0(i) = max(where(y_new(i) GE y))
   jy0 = jy0 > 0 & jy0 = jy0 < (jpix-2) ;limits on jy0
   jy1 = jy0+1

;Now you need the positions in the array given by these subscripts
;All four corners, also you need the increments as arrays, a whole lotta memory
;Check Numerical Recipies, sec 3.6
;ok, you also need to be sure that your x and y coordinates aren't integers
   typx = size(x) & typx = typx(typx(0)+1)
   typxn = size(x_new) & typxn = typxn(typxn(0)+1)
   IF(typx LE 2) THEN x0 = float(x) ELSE x0 = x
   IF(typxn LE 2) THEN xn = float(x_new) ELSE xn = x_new

   typy = size(y) & typy = typy(typy(0)+1)
   typyn = size(y_new) & typyn = typyn(typyn(0)+1)
   IF(typy LE 2) THEN y0 = float(y) ELSE y0 = y
   IF(typyn LE 2) THEN yn = float(y_new) ELSE yn = y_new

   IF(siz_a(3) LE 2) THEN a1 = fltarr(nx, ny) ELSE a1 = replicate(a(0), nx, ny)
   a1(*) = 0
   a2 = a1 & a3 = a2 & a4 = a3 & t = a4 & u = t

   IF(qunc) THEN BEGIN
      unc_t2 = t
      unc_u2 = u
      ua1 = a1 & ua2 = a2 & ua3 = a3 & ua4 = a4
   ENDIF

;deal with zero values
   dx0 = x0(ix1)-x0(ix0)
   x0 = xn-x0(ix0)
   dx0e0 = where(dx0 EQ 0.0)
   dx0n0 = where(dx0 NE 0.0)
   dy0 = y0(jy1)-y0(jy0)
   y0 = yn-y0(jy0)
   dy0e0 = where(dy0 EQ 0.0)
   dy0n0 = where(dy0 NE 0.0)

   FOR i = 0, nx-1 DO BEGIN
      a1(i, *) = a(ix0(i), jy0)
      a2(i, *) = a(ix1(i), jy0)
      a3(i, *) = a(ix1(i), jy1)
      a4(i, *) = a(ix0(i), jy1)
      IF(dy0e0(0) NE -1) THEN u(i, dy0e0) = 0.5
      IF(dy0n0(0) NE -1) THEN u(i, dy0n0) = y0(dy0n0)/dy0(dy0n0)
      IF(qunc) THEN BEGIN
         ua1(i, *) = unci(ix0(i), jy0)
         ua2(i, *) = unci(ix1(i), jy0)
         ua3(i, *) = unci(ix1(i), jy1)
         ua4(i, *) = unci(ix0(i), jy1)
         IF(dy0e0(0) NE -1) THEN unc_u2(i, dy0e0) = 0.25
         IF(dy0n0(0) NE -1) THEN unc_u2(i, dy0n0) = (uncy(dy0n0)/dy0(dy0n0))^2
      ENDIF
   ENDFOR
   FOR j = 0, ny-1 DO BEGIN
      IF(dx0e0(0) NE -1) THEN t(dx0e0, j) = 0.5
      IF(dx0n0(0) NE -1) THEN t(dx0n0, j) = x0(dx0n0)/dx0(dx0n0)
      IF(qunc) THEN BEGIN
         IF(dx0e0(0) NE -1) THEN unc_t2(dx0e0, j) = 0.25
         IF(dx0n0(0) NE -1) THEN unc_t2(dx0n0, j) = (uncx/dx0(dx0n0))^2
      ENDIF
   ENDFOR

   t1 = 1.0-t & u1 = 1.0-u
   f = t1*u1*a1+t*u1*a2+t*u*a3+t1*u*a4
   IF(qunc) THEN BEGIN
      out_unc = sqrt(unc_t2*(u1*(a2-a1)+u*(a3-a4))^2 $
                +unc_u2*(t1*(a4-a1)+t*(a3-a2))^2 $
                +(ua1*u1*t1)^2+(ua2*t*u1)^2+(ua3*t*u)^2+(ua4*t1*u)^2)
   ENDIF ELSE out_unc = 0.0

   delvarx, a1, a2, a3, a4
   delvarx, t, u, xn, x0, yn, y0, dx0, dy0
   delvarx, a, x, y
   
   IF(qunc) THEN delvarx, unci, unc_t2, unc_u2, ua1, ua2, ua3, ua4
   
   RETURN, f
END

      

