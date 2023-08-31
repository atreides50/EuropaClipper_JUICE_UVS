;
;+
;  checks for gaps in the data and replace them with NAN
;-------------------------------------------------------------------------------
PRO fix_gaps, times,data, RATIO=RATIO

  gaps = find_gaps (times)
  if (gaps[0] ne -1) then begin
    case SIZE(data, /TYPE) of
      4: data[gaps] = !VALUES.F_NAN
      5: data[gaps] = !VALUES.D_NAN
      else : begin
        data = float(data)
        data[gaps] = !VALUES.F_NAN
      endelse
    endcase
  endif
end

;+------------------------------------------------------------------------
;$Author: rchimiak $
;$Date: 2016/03/21 15:41:47 $
;$Header: /home/cdaweb/dev/control/RCS/overlay.pro,v 1.1 2016/03/21 15:41:47 rchimiak Exp rchimiak $
;$Locker: rchimiak $
;$Revision: 1.1 $
;+------------------------------------------------------------------------
; Description:
;    graph an element of a set of time series plots on a single panel
;
; Params:
;    i = order of the elment being plotted
;
;    iter_per_panel = number of elements that will be plotted on
;                     that panel
;    mytimes = the abscissa values to be plotted
;
;    mydata = the ordinate data to be plotted
;
;    psize = panel hekght
;
;
; Keywords:
;    YUNIT
;       Y axis left label
;
;    YTITLE
;       Y axis right label
;
;    XRANGE
;       min and max abscissa values to be plotted
;
;    YRANGE
;       min and max values to be plotted
;
;    YLOG
;       specifies logarithmic or linear Y axis
;
;    POSITION
;       4-element vector giving the lower left and upper right corners
;          of the panel
;
;    NOGAPS
;       if set, gaps in the data will be ignored
;
;    NOERASE
;       specifies that the previous plot is not to be erased when running
;          the plot procedure.
;
;    _EXTRA
;       allows properties inheritance from one graphic to be used for other graphics.
;
;    YTICK_GET
;       return the values of the tick marks for the y axis
;
;    COLOR
;       designated color for that element
;
; Output:
;       out = status flag, 0=0k, -1 = problem occured.
;
;------------------------------------------------------------------
;
FUNCTION overlay, i,iter_per_panel,mytimes,mydata, YUNIT=yunit ,YTITLE=ylabel,YRANGE=yranger,$
  YLOG=yscaletype,XRANGE=xranger,POSITION=ppos, NOGAPS=NOGAPS, $
  NOERASE=clear_plot,_EXTRA=EXTRAS,ytick_get=yticks,psize,color = color, psym, first

  ; search for data gaps
  if N_ELEMENTS(NOGAPS) eq 0  then fix_gaps, mytimes,mydata

  thick = psym ne 0?  2:1
  symsize = psym ne 0? 2:1
  
  
  if(i eq first  ) then begin

  ;if (i EQ 0) then begin

    ycsize = 1.0 & ylength = strlen(ylabel)
    if ((!d.x_ch_size * ylength) gt psize) then begin
      ratio    = float(!d.x_ch_size * ylength) / float(psize)
      ycsize = 1.0 - (ratio/8.0) + 0.1
    endif

    if (yscaletype) then begin ;log scaling -

      plot,mytimes,mydata,/NODATA,YRANGE=yranger,YSTYLE=2+4,$
        YLOG=yscaletype,XSTYLE=4+1,XRANGE=xranger,POSITION=ppos,/DEVICE,$
        NOERASE=clear_plot,CHARSIZE=ycsize,_EXTRA=EXTRAS,ytick_get=yticks,$
        PSYM = psym,THICK= thick,SYMSIZE = symsize

      wle = where(mydata le 0.0,wcle)
      if (wcle gt 0) then begin
        mydata[wle] = yticks[0]
      endif

      if (n_elements(yticks) gt 0) then begin
        yranger[0] = min(yticks)
        yranger[1] = max(yticks)
      endif

      plot,mytimes,mydata,/NODATA,YRANGE=yranger,YSTYLE=1,$
        YLOG=yscaletype,XSTYLE=4+1,XRANGE=xranger,POSITION=ppos,/DEVICE,$
        NOERASE=clear_plot,CHARSIZE=ycsize,_EXTRA=EXTRAS, YTITLE = yunit,color = 1,$
        PSYM = psym,THICK= thick,SYMSIZE = symsize

    endif else begin ;linear scaling
      if (abs(yranger[1]) gt 999 and abs(yranger[1]) lt 99999) then begin

        plot,mytimes,mydata,/NODATA,YRANGE=yranger,YSTYLE=2,$
          YLOG=yscaletype,XSTYLE=4+1,ytickformat='(F11.1)',XRANGE=xranger,POSITION=ppos,/DEVICE,$
          NOERASE=clear_plot,CHARSIZE=ycsize,_EXTRA=EXTRAS, YTITLE = yunit,color = 1,$
          PSYM = psym,THICK= thick,SYMSIZE = symsize

      endif else if ((abs(yranger[1]) lt 1.0) and (abs(yranger[0]) lt 1.0) and (psize ge 100 and psize lt 5000)) then begin

        IF  ((where (abs (yranger) lt 1.E-5)) [0] eq -1) THEN fstring = '(F9.5)' ELSE $
          IF  ((where (yranger lt 0)) [0] eq -1) THEN fstring = '(E9.3)' ELSE $
          fstring = '(E9.2)'

        plot,mytimes,mydata,/NODATA,YRANGE=yranger,YSTYLE=2,$
          YLOG=yscaletype,XSTYLE=4+1,YTICKFORMAT=fstring,XRANGE=xranger,POSITION=ppos,/DEVICE,$
          NOERASE=clear_plot,CHARSIZE=ycsize,_EXTRA=EXTRAS, YTITLE = yunit,color = 1,$
          PSYM = psym,THICK= thick,SYMSIZE = symsize
      endif else begin

        plot,mytimes,mydata,/NODATA,YRANGE=yranger,YSTYLE=2,$
          YLOG=yscaletype,XSTYLE=4+1,XRANGE=xranger,POSITION=ppos,/DEVICE,$
          NOERASE=clear_plot,CHARSIZE=ycsize,_EXTRA=EXTRAS, YTITLE = yunit,color = 1,$
          PSYM = psym,THICK= thick,SYMSIZE = symsize
      endelse
    endelse
  endif

  xloc = ppos[2] + !d.x_ch_size * 2

  top = ((ppos[3] -ppos[1])-((12 )*iter_per_panel))/2
  yloc = ppos[3] - ((!d.x_ch_size * 2 )*(i ) + top)


  oplot,mytimes,mydata, color=color,_EXTRA=EXTRAS, PSYM = psym,THICK= thick,SYMSIZE = symsize

  xyouts, xloc,yloc , ylabel, color=color,  /device

  return,0
end

