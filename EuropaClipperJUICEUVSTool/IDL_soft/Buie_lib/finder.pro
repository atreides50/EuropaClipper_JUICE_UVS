;  S28:03:35 E21:01:33
;+
; NAME:
;  finder
; PURPOSE:   (one line only)
;  Interactive finder chart tool
; DESCRIPTION:
;  This widget tool will allow you to load a FITS image with astrometric
;    information (format generated by astinfo.pro).  From this starting
;    point it will resample the image to the scale and orientation needed
;    to match your telescope or instrument system.  It has modes to permit
;    tracking an object as well as controlling orientation for equatorial
;    or alt-az telescopes (with no de-rotator).
;
;  In the main image display window a left click will place the marked at
;    that position.  As you move around the window (without clicking) you
;    see the coordinates under the cursor and the offset from the current
;    marker position.
;
;  Toolbar functions:
;    File
;      Open Image
;        Browse and find a FITS image to be displayed.  Upon sucessfully
;          loading an image with astrometric information the display is reset
;          for the current scale and orientation but putting the image center
;          and marker at the center of this image.  Observatory and time
;          settings are not changed.
;      Save as PNG
;        Snapshot of screen image to a png format graphics file.  The name is
;          automatically generated.  The first part of the file name is the
;          observatory string as shown in the widget.  Next, the current date
;          and time is appended.  These three fields are separated by "_" and
;          file suffix is .png.
;      Exit
;        Quit program.  There is no auto-save of the configuration.
;
;    Tools
;      Set Position Angle
;        You are prompted for a new position angle for the display.  If in
;          equatorial mode this the position of north on the display measured
;          clockwise from up.  Center and marker positions are not affected.
;      Toggle Horizon Mode
;        There are two modes, equatorial and local horizon modes.  In equatorial
;          mode the normal display is north up.  in local horizon mode, the
;          normal display is the zenith direction to be up.  Any position
;          angle in effect is unchanged.
;      Toggle Image Flip
;        Change the handedness of the display.  The normal display is
;        sky-normal (with no rotation and equatorial mode, north is up and
;        east is to the left).  This is implemented as an inversion in the
;        RA axis.  That means you cannot control the direction of north with
;        this control.  Use the position angle control instead.
;      Marker to Center
;        Shift location of marker to match the current center of the image.
;      Center On Marker
;        Shift location of image center to match the current position of the
;          marker.
;
;    Config
;      Load Configuration
;        Load and use a configuration setup.  See discussion of CONFIG keyword
;           provided below.
;      Image Size
;        Change image size. You will be asked to input two numbers, the x and
;          y sizes of the image to change to.
;      Image X Size
;        Change image X size. You will be asked to input one number for the
;          new x size of the image.
;      Image Y Size
;        Change image Y size. You will be asked to input one number for the
;          new y size of the image.
;      Image Scale
;        Change the image scale to the provided number in arcsec/pixel.
;      Last Config
;        Not implemented.
;
; CATEGORY:
;  Astronomy
; CALLING SEQUENCE:
;  finder
; INPUTS:
; OPTIONAL INPUT PARAMETERS:
; KEYWORD INPUT PARAMETERS:
;  CONFIG - Name of a configuration file to load on startup.  File suffix used
;             for this is '.fdr'.  A configuration file saves the image
;             display, orientation, scale information, and the observatory
;             information.  At present, the only way to get such a file is to
;             make it yourself by hand.  The format is as follows:
;
;    Line 1 - ID line, must say FINDER v1.0 starting at column 1.
;    Line 2 - observatory code or location enclosed in quotes.  An observatory
;                code is a 3-character string as defined by the Minor Planet
;                Center or a a manual position where you list the latitude
;                and longitude of the observatory location.  You can provide
;                this in either sexigesimal notation or decimal degrees
;                (lat and lon are both in degrees in this case).  Direction
;                from prime meridian and equator is denoted by a letter (not a
;                sign) -- E for east, W for west, N for north and S for south.
;    Line 3 - xsize of displayed image.  This is limited to be no bigger than
;                80% of your overall screen size.
;    Line 4 - ysize of displayed image.  This limited to be no bigger than 95%
;                of your overall screen size.
;    Line 5 - image scale for displayed image (arcsec/pixel)
;    Line 6 - Image flip, 0=no, 1=yes
;    Line 7 - Horizon mode, 0=equatorial, 1=local horizon
;    Line 8 - position angle (degrees)
;             
; OUTPUTS:
; KEYWORD OUTPUT PARAMETERS:
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
; PROCEDURE:
; MODIFICATION HISTORY:
;  2010/06/22, Written by Marc W. Buie, Southwest Research Institute
;  2010/07/09, MWB, added numerous features
;  2011/03/21, MWB, fixed some of the control logic related to the marker
;                     tools and added a new "marker to center" tool.
;  2016/06/02, MWB, converted to usage of astcvt tools, added support for
;                     "standard" WCS supported by Astronomy Users Library
;                     tools.  My astrometry information is searched for first,
;                     if not found will try extast.
;  2016/08/05, MWB, fixed a bug that caused the image to be displayed with the
;                     wrong orientation when in the horizon-lock mode.  The
;                     image was actually self-consistent with the labels but
;                     was not the orientation requested.
;-
pro finder_cleanup, tlb

   ; get pointer to state structure
   widget_control, tlb, get_uvalue=state

   ; Free up any dynamically allocated space with the state structure
   ptr_free,(*state).pastinfo
   ptr_free,(*state).pimage
   ptr_free,(*state).psyninfo
   ptr_free,(*state).psynimage

   ; Free up the state structure itself.
   ptr_free, state

end

pro finder_loadconfig,fn,valid,state

   valid=0
   if not exists(fn) then begin
      print,'Configuration file ',fn,' does not exist.'
      return
   endif

   openr,lun,fn,/get_lun
   line=''
   readf,lun,line,format='(a)'
   if line ne 'FINDER v1.0' then begin
      print,'Configuration file ',fn,' has an invalid version or format.'
      return
   endif
   ; get the observatory code or location
   readf,lun,line,format='(a)'
   pos=strpos(line,"'")
   if pos lt 0 then return
   line=strmid(line,pos+1)
   pos=strpos(line,"'")
   if pos lt 0 then return
   line=strmid(line,0,pos)
   obscode=line
   ; Get the size
   xsize=0
   ysize=0
   flip=0
   horzmode=0
   readf,lun,xsize
   readf,lun,ysize
   readf,lun,scale
   readf,lun,flip
   readf,lun,horzmode
   readf,lun,posang
   free_lun,lun

help,xsize,ysize,scale,flip,horzmode,posang

   finder_setobs,obscode,valid,state
   if not valid then begin
      print,'Observatory ',obscode,' not valid.'
      return
   endif

   scrsz=get_screen_size()
   (*state).xsize    = (xsize < fix(scrsz[0]*0.8 )) > 100
   (*state).ysize    = (ysize < fix(scrsz[0]*0.95)) > 100
   widget_control,(*state).drawwin, $
      draw_xsize=(*state).xsize, $
      draw_ysize=(*state).ysize
   (*state).scale    = (scale < 10.0) > 0.001
   (*state).xflip    = flip ne 0
   (*state).horzmode = flip ne 0
   (*state).posang   = posang
   valid=1
end

pro finder_markerupdate,state,reset

   widget_control,(*state).taglabel,get_value=cens
   words=strsplit(cens,' ',/extract)

   if n_elements(words) eq 1 then begin
      if (*state).obsname eq 'manual location' then obscode='500' $
      else obscode=(*state).obscode
      ephem,(*state).jd,obscode,2,words[0],eph
      (*state).ratag=eph[0]
      (*state).dectag=eph[1]
   endif else if reset then begin
      (*state).ratag = (*state).racen
      (*state).dectag = (*state).deccen
      rastr,(*state).ratag,1,ras
      decstr,(*state).dectag,0,decs
      widget_control,(*state).taglabel,set_value=ras+' '+decs
   endif else begin
      ratag=raparse(words[0])
      dectag=decparse(words[1])
      (*state).ratag = ratag
      (*state).dectag = dectag
      rastr,(*state).ratag,1,ras
      decstr,(*state).dectag,0,decs
      widget_control,(*state).taglabel,set_value=ras+' '+decs
   endelse
   
end

; reset
; 0 - image resampling not modified, but overlay needs to be regenerated.
;       starts from already resampled image and rebuilds the display.  This
;       is the fastest option.
; 1 - start over from scratch, rebuild resampled image, reset center and marker
; 2 - rebuild resampled image, keep current center and marker
pro finder_refresh,state,reset

   if not ptr_valid((*state).pimage) then return

   if (*state).autotime then begin
      (*state).jd=systime(/julian,/ut)
      widget_control,(*state).timerid,timer=60.0
   endif
   jdstr,(*state).jd,0,jds
   widget_control,(*state).utid,set_value=jds

   sz=size((*(*state).pimage),/dimen)
   imnx=sz[0]
   imny=sz[1]

   scales=strtrim(string((*state).scale,format='(f10.3)'),2)
   widget_control,(*state).scaleid,set_value=scales

   fov = (*state).scale*sqrt(float((*state).xsize)^2+float((*state).ysize)^2)
   fovs=strtrim(string(fov,format='(f10.1)'),2)
   widget_control,(*state).fovid,set_value=fovs

   if reset eq 1 then begin
      if (*state).wcstype eq 0 then begin
         xy2ad,imnx/2.0,imny/2.0,(*(*state).pastinfo),ra,dec
         ra=ra*!dpi/180.0d0
         dec=dec*!dpi/180.0d0
      endif else begin
         astcvt,'xy',imnx/2.0,imny/2.0,(*(*state).pastinfo),'rd',ra,dec
      endelse
      (*state).ratag = ra
      (*state).dectag = dec
      rastr,ra,1,ras
      decstr,dec,0,decs
      widget_control,(*state).cenlabel,set_value=ras+' '+decs
      mkastinfo,ra,dec,(*state).xsize/2.0,(*state).ysize/2.0,(*state).scale, $
         syninfo,xflip=(*state).xflip,yflip=(*state).yflip, $
         posang=(*state).posang+(*state).zenang
      ptr_free,(*state).psyninfo
      (*state).psyninfo=ptr_new(syninfo)
      dirty=1
   endif else if reset eq 2 then begin
      if (*state).wcstype eq 0 then begin
         xy2ad,imnx/2.0,imny/2.0,(*(*state).pastinfo),ra,dec
         ra=ra*!dpi/180.0d0
         dec=dec*!dpi/180.0d0
      endif else begin
         astcvt,'xy',imnx/2.0,imny/2.0,(*(*state).pastinfo),'rd',ra,dec
      endelse
      mkastinfo,ra,dec,(*state).xsize/2.0,(*state).ysize/2.0,(*state).scale, $
         syninfo,xflip=(*state).xflip,yflip=(*state).yflip, $
         posang=(*state).posang+(*state).zenang
      ptr_free,(*state).psyninfo
      (*state).psyninfo=ptr_new(syninfo)
      dirty=1
   endif else begin
      dirty=0
   endelse

   ; Special handling for horizon mode
   if (*state).horzmode then begin
      mkastinfo,(*state).ratag,(*state).dectag, $
                (*state).xsize/2.0,(*state).ysize/2.0,(*state).scale, $
                syninfo,xflip=(*state).xflip,yflip=(*state).yflip,posang=0.0d0
      x0=(*state).xsize/2
      y0=(*state).ysize/2
      dray= 60.0d0/3600.0d0*!dpi/180.0d0
      astcvt,'xy',x0,y0,syninfo,'rd',ra0,dec0
      hangle,(*state).jd,ra0,dec0,(*state).obslat,(*state).obslon,ha0,lst0
      altaz,ha0,(*state).obslat,dec0,alt0,az0
      lcltoeq,alt0+dray,az0,(*state).obslat,ha1,dec1
      ra1=lst0-ha1
      astcvt,'rd',ra1,dec1,syninfo,'xy',xray,yray
      lpa = atan(yray-y0,xray-x0) * !radeg
      (*state).zenang=lpa-90
      dirty=1
   endif

   widget_control,(*state).cenlabel,get_value=cens
   words=strsplit(cens,' ',/extract)
   ra=raparse(words[0])
   dec=decparse(words[1])

   if ra ne (*state).racen or dec ne (*state).deccen or dirty then begin
      mkastinfo,ra,dec,(*state).xsize/2.0,(*state).ysize/2.0,(*state).scale, $
         syninfo,xflip=(*state).xflip,yflip=(*state).yflip, $
         posang=(*state).posang+(*state).zenang
      ptr_free,(*state).psyninfo
      (*state).psyninfo=ptr_new(syninfo)

      dewarp,(*(*state).pastinfo),(*(*state).pimage),(*(*state).psyninfo), $
         newimage,(*state).xsize,(*state).ysize
      ptr_free,(*state).psynimage
      (*state).psynimage=ptr_new(newimage,/no_copy)
      (*state).racen = ra
      (*state).deccen = dec
   endif

   finder_markerupdate,state,reset

   rastr,(*state).ratag,1,ras
   decstr,(*state).dectag,0,decs
   widget_control,(*state).markerid,set_value=ras+' '+decs

   ; Figure out local circumstances
   am=airmass((*state).jd,(*state).ratag,(*state).dectag, $
              (*state).obslat,(*state).obslon,alt=alt,lha=lha,lst=lst,azi=azi)
   ams=string(am<9.5,format='(f10.2)')
   if am ge 9.5 then ams=ams+'+'
   widget_control,(*state).airmassid,set_value=strcompress(ams,/remove_all)
   alts=string(alt*!radeg,format='(f10.1)')
   widget_control,(*state).altitudeid, $
      set_value=strcompress(alts,/remove_all)+' deg'
   hastr,lha,-2,lhas
   widget_control,(*state).haid,set_value=lhas

   tmpimage=(*(*state).psynimage)+ $
      randomn(seed,n_elements((*(*state).psynimage)))*(*state).noise + $
                                                      (*state).noise*3.0
   
   skysclim,tmpimage,loval,hival,meanval,sigval,npts=30000
   hival=meanval+10*sigval

   widget_control,(*state).drawwin,get_value=win
   wset,win
   tv,bytscl(tmpimage,min=loval,max=hival,top=255)

   x0=(*state).xsize/2
   y0=(*state).ysize/2
   dray= 60.0d0/3600.0d0*!dpi/180.0d0
   astcvt,'xy',x0,y0,(*(*state).psyninfo),'rd',ra0,dec0

   astcvt,'rd',ra0,dec0+dray,(*(*state).psyninfo),'xy',xray,yray
   npa = atan(yray-y0,xray-x0) * !radeg

   astcvt,'rd',ra0+dray,dec0,(*(*state).psyninfo),'xy',xray,yray
   epa = atan(yray-y0,xray-x0) * !radeg

   hangle,(*state).jd,ra0,dec0,(*state).obslat,(*state).obslon,ha0,lst0
   altaz,ha0,(*state).obslat,dec0,alt0,az0
   lcltoeq,alt0,az0,(*state).obslat,testha,testdec

   lcltoeq,alt0+dray,az0,(*state).obslat,ha1,dec1
   ra1=lst0-ha1
   astcvt,'rd',ra1,dec1,(*(*state).psyninfo),'xy',xray,yray
   lpa = atan(yray-y0,xray-x0) * !radeg

   lcltoeq,alt0,az0+dray,(*state).obslat,ha1,dec1
   ra1=lst0-ha1
   astcvt,'rd',ra1,dec1,(*(*state).psyninfo),'xy',xray,yray
   zpa = atan(yray-y0,xray-x0) * !radeg

   one_arrow,60,60,npa,'N',color='0070ff'xl
   one_arrow,60,60,epa,'E',color='0070ff'xl

;   ; alt/az compass
   one_arrow,(*state).xsize-60,60,lpa,'Z',color='00ffff'xl
   one_arrow,(*state).xsize-60,60,zpa,'R',color='00ffff'xl

   astcvt,'rd',(*state).ratag,(*state).dectag,(*(*state).psyninfo), $
          'xy',xtag,ytag

   ; marker for object
   hole=10
   len =20
   ang = 0
   one_ray,xtag+hole,ytag,len,  0+ang,color='0000ff'xl,thick=2
   one_ray,xtag,ytag+hole,len, 90+ang,color='0000ff'xl,thick=2
   one_ray,xtag-hole,ytag,len,180+ang,color='0000ff'xl,thick=2
   one_ray,xtag,ytag-hole,len,270+ang,color='0000ff'xl,thick=2

end

pro finder_setobs,obsname,valid,state
   valid=0
   words=strsplit(obsname,' ',/extract)
   if n_elements(words) eq 1 then begin
      getobloc,words[0],obs
      if obs.name eq 'unknown' then begin
         widget_control,(*state).obslabel,set_value=(*state).obsname
         valid=0
      endif else begin
         (*state).obscode = words[0]
         (*state).obsname = obs.name
         (*state).obslon = obs.lon
         (*state).obslat = obs.lat
      endelse
   endif else begin
      cvtsixty,words[0],-1.0*!dpi/2.0,!dpi/2.0,0,['N','S'],lat
      cvtsixty,words[1],0.0d0,2.0d0*!dpi,1,['W','E'],lon
      (*state).obscode = words[0]+' '+words[1]
      (*state).obsname = 'manual location'
      (*state).obslon = lon
      (*state).obslat = lat
   endelse
   widget_control,(*state).obslabel,set_value=(*state).obscode
   widget_control,(*state).obsnameid,set_value=(*state).obsname
   valid=1
end

pro finder_eve, event

   widget_control, event.top, GET_UVALUE=state

   if event.id eq (*state).mainbase then $
      event_name = 'Mainbase' $
   else $
      widget_control, event.id,  GET_UVALUE=event_name, /HOURGLASS

   exit = event_name eq 'THE_MENU'
   if exit then exit = event.value eq 'Exit'

   reset=0

   case event_name of

      'THE_MENU': begin
         case event.value of

            'Center On Marker': begin
               finder_markerupdate,state,0
               rastr,(*state).ratag,1,ras
               decstr,(*state).dectag,0,decs
               ; put the new position in the widget, refresh will pick that
               ;  up as a change and will refresh the view and the state
               ;  accordingly
               widget_control,(*state).cenlabel,set_value=ras+' '+decs
               finder_refresh,state,0
            end

            'Extra Noise': begin
               ans=qinput(default=(*state).noise, $
                          group_leader=(*state).mainbase, $
                          prompt='New extra noise level (DN)',/FLOAT, $
                          cancelled=noinput)
               if not noinput then begin
                  (*state).noise=float(ans)
                  str=strtrim(string((*state).noise,format='(f10.1)'),2)
                  widget_control,(*state).noiseid,set_value=str
                  finder_refresh,state,2
               endif
            end

            'Marker to Center': begin
               finder_markerupdate,state,1
               finder_refresh,state,0
            end

            'Image Size': begin
               default= ((*state).xsize + (*state).ysize)/2
               ans=qinput(default=default,group_leader=(*state).mainbase, $
                          prompt='New image size',/INTEGER, $
                          cancelled=noinput)
               if not noinput then begin
                  scrsz=get_screen_size()
                  (*state).xsize = fix(ans) < fix(scrsz[0]*0.8)
                  (*state).ysize = fix(ans) < fix(scrsz[1]*0.95)
                  widget_control,(*state).drawwin, $
                     draw_xsize=(*state).xsize, $
                     draw_ysize=(*state).ysize
                  finder_refresh,state,2
               endif
            end

            'Image X Size': begin
               default= (*state).xsize
               ans=qinput(default=default,group_leader=(*state).mainbase, $
                          prompt='New image X size',/INTEGER, $
                          cancelled=noinput)
               if not noinput then begin
                  scrsz=get_screen_size()
                  (*state).xsize = fix(ans) < fix(scrsz[0]*0.8)
                  widget_control,(*state).drawwin, $
                     draw_xsize=(*state).xsize
                  finder_refresh,state,2
               endif
            end

            'Image Y Size': begin
               default= (*state).ysize
               ans=qinput(default=default,group_leader=(*state).mainbase, $
                          prompt='New image Y size',/INTEGER, $
                          cancelled=noinput)
               if not noinput then begin
                  scrsz=get_screen_size()
                  (*state).ysize = fix(ans) < fix(scrsz[1]*0.95)
                  widget_control,(*state).drawwin, $
                     draw_ysize=(*state).ysize
                  finder_refresh,state,2
               endif
            end

            'Image Scale': begin
               ans=qinput(default=(*state).scale, $
                          group_leader=(*state).mainbase, $
                          prompt='New Image Scale (arcsec/pixel)',/FLOATING, $
                          cancelled=noinput)
               if not noinput then begin
                  (*state).scale = (ans < 10.0) > 0.001
                  finder_refresh,state,2
               endif
            end

            'Open Image': begin
               fn = dialog_pickfile(group=event.top,TITLE='Select Image File', $
                                    /must_exist,path=(*state).fnpath, $
                                    get_path=newpath)
               if fn ne '' then begin
                  fn=strmid(fn,strlen(newpath))
                  image=readfits(newpath+fn,hdr)
                  astinfo,hdr,astinfo,error,/silent
                  if not error then begin
                     (*state).wcstype=1
                     (*state).fnpath=newpath
                     (*state).filename=strmid(fn,strlen(newpath))
                     ptr_free,(*state).pimage
                     (*state).pimage=ptr_new(image,/no_copy)
                     (*state).pastinfo=ptr_new(astinfo,/no_copy)
                     finder_refresh,state,1
                     widget_control,(*state).fnlabel,set_value=fn
                  endif else begin
                     extast,hdr,astinfo,result
                     if result gt 0 then begin
                        (*state).wcstype=0
                        (*state).fnpath=newpath
                        (*state).filename=strmid(fn,strlen(newpath))
                        ptr_free,(*state).pimage
                        (*state).pimage=ptr_new(image,/no_copy)
                        (*state).pastinfo=ptr_new(astinfo,/no_copy)
                        finder_refresh,state,1
                        widget_control,(*state).fnlabel,set_value=fn
                     endif else begin
                        print,'File ',newpath+fn, $
                              ' does not have valid astrometric info'
                     endelse
                  endelse
               endif
            end

            'Load Configuration': begin
               fn = dialog_pickfile(group=event.top, $
                                    TITLE='Select Configuration File', $
                                    filter='*.fdr', $
                                    /must_exist,path=(*state).fnpath, $
                                    get_path=newpath)
               if fn ne '' then begin
                  finder_loadconfig,fn,valid,state
                  if valid then finder_refresh,state,2
               endif
            end

            'Reset to Sky Normal': begin
               (*state).posang = 0.0d0
               (*state).horzmode=0
               (*state).xflip=0
               (*state).zenang=0.0d0
               finder_refresh,state,2
            end

            'Set Position Angle': begin
               ans=qinput(default=(*state).posang, $
                          group_leader=(*state).mainbase, $
                          prompt='New position angle',/FLOATING, $
                          cancelled=noinput)
               if not noinput then begin
                  (*state).posang = double(ans)
                  finder_refresh,state,2
               endif
            end

            'Save as PNG': begin
               if not ptr_valid((*state).pimage) then return
               jdstr,(*state).jd,0,jds
               widget_control,(*state).drawwin,get_value=win
               fn=(*state).obscode+' '+jds
               fn=strtrim(strcompress(fn),2)
               fn=repchar(fn,'/','-')
               fn=repchar(fn,' ','_')+'.png'
               print,'Saving image to ',fn
               tvgrab,fn,win,/png
            end

            'Toggle Horizon Mode': begin
               if (*state).horzmode then begin
                  (*state).horzmode=0
               endif else begin
                  (*state).horzmode=1
               endelse
               (*state).zenang=0.0d0
               finder_refresh,state,2
            end

            'Toggle Image Flip': begin
               if (*state).xflip then (*state).xflip=0 else (*state).xflip=1
               finder_refresh,state,2
            end

            'Exit' : begin
               widget_control, event.top, /DESTROY
               return
            end

            else: begin
               message, 'Unknown menu event:', /INFO
               help, event, /STRUCTURE
            end

         endcase

      end ; THE_MENU

      'Set Center': begin
         widget_control,(*state).cenlabel,get_value=cens
         if strupcase(cens) eq 'CENTER' then reset=1 else reset=0
         finder_refresh,state,reset
      end

      'Set Marker': begin
         finder_refresh,state,0
      end

      'Set Observatory': begin
         widget_control,(*state).obslabel,get_value=cens
         finder_setobs,cens,valid,state
         if not valid then return
;;!! need to rebuild the proper string if invalid,
;;!! obscode and manual must be handled differently,
;;!! only need to refresh (*state).obslabel widget
         finder_refresh,state,0
      end

      'Set Time': begin
         widget_control,(*state).timelabel,get_value=cens
         words=strsplit(cens,' ',/extract)
         if n_elements(words) eq 1 then begin
            case strupcase(words[0]) of
               'AUTO': begin
                  (*state).autotime = 1
               end
               'NOW': begin
                  (*state).autotime = 0
                  (*state).jd=systime(/julian,/ut)
               end
               else: begin
; put back what was already there
; 2010/06/24 08:00 18:16:44.7 -18:15:10
; 2010/06/25 08:00 18:16:38.3 -18:15:19
;
; 2010/06/26 07:00 18:16:32.1 -18:15:27
; 2010/06/27 07:00 18:16:25.6 -18:15:36
; 2010/06/28 07:00 18:16:19.2 -18:15:46
; 2010/06/29 07:00 18:16:12.8 -18:15:55
; 2010/06/30 07:00 18:16:06.4 -18:16:04
; 2010/07/01 07:00 18:15:59.9 -18:16:14 slight problem at start with field star
               endelse
            end
         endif else begin
            (*state).autotime = 0
            jd=jdparse(cens,errflg=error)
            if error then begin
               (*state).jd=systime(/julian,ut)
            endif else begin
               (*state).jd=jd
            endelse
               
         endelse
         finder_refresh,state,0
      end

      'Timer': begin
         finder_refresh,state,0
      end

      'Window': begin
         if not ptr_valid((*state).pimage) then return
         if event.type eq 2 then begin
            astcvt,'xy',event.x,event.y,(*(*state).psyninfo),'rd',ra,dec
;            astxy2rd,event.x,event.y,(*(*state).psyninfo),ra,dec,/full
            rastr,ra,1,ras
            decstr,dec,0,decs
            widget_control,(*state).motionid, $
               set_value=strn(event.x,length=3)+' '+strn(event.y,length=3)+ $
                         ' '+ras+' '+decs
            sep=angsep(ra,dec,(*state).ratag,(*state).dectag)
            sep=sep*180.0d0/!dpi*3600.0d0 ; convert to arcsec
            str='offset '+string(sep,format='(f10.1)')+' arcsec'
            str=strcompress(str)
            widget_control,(*state).offsetid,set_value=str
            dra = (ra-(*state).ratag)*cos((*state).dectag)*!radeg*3600.0
            ddec = (dec-(*state).dectag)*!radeg*3600.0
            radir='E'
            if dra lt 0.0 then radir='W'
            decdir='N'
            if ddec lt 0.0 then decdir='S'
            str='offset '+string(abs(dra),format='(f10.1)')+radir
            str=str+string(abs(ddec),format='(f10.1)')+decdir+' arcsec'
            str=strcompress(str)
            widget_control,(*state).coffsetid,set_value=str
         endif else if event.type eq 0 then begin
            astcvt,'xy',event.x,event.y,(*(*state).psyninfo),'rd',ra,dec
;            astxy2rd,event.x,event.y,(*(*state).psyninfo),ra,dec,/full
            rastr,ra,1,ras
            decstr,dec,0,decs
            widget_control,(*state).taglabel,set_value=ras+' '+decs
            finder_refresh,state,0
         endif else if event.type eq 1 then begin
            ; do nothing
         endif else begin
            print,'EVENT NAME: ',event_name
            message, 'Unknown event:', /INFO
            help, event, /structure
         endelse
      end

      else: begin
         print,'EVENT NAME: ',event_name
         message, 'Unknown event:', /INFO
         help, event, /STRUCTURE
      end

   endcase

end ; end of event handler

pro finder,CONFIG=config

   ; optional
   if xregistered('finder') then return

   if (!d.flags and 256) eq 0 then begin
      print, 'Error. No windowing device. FINDER cannot be started.'
      return
   endif

   self='FINDER: '
   if badpar(config,[0,7],0,caller=self+'(CONFIG) ',default='') then return

   ;Define the main base.
   mainbase = widget_base( TITLE='FINDER: Widget Template', $
                           /COLUMN, UVALUE=0, MBAR=bar )

   menu = CW_PdMenu(bar, /RETURN_NAME, $
                    ['1\File',$
                     '0\Open Image',$
                     '0\Save as PNG',$
                     '2\Exit',$
                     '1\Tools',$
                     '0\Reset to Sky Normal', $
                     '0\Set Position Angle', $
                     '0\Toggle Horizon Mode', $
                     '0\Toggle Image Flip', $
                     '0\Marker to Center', $
                     '2\Center On Marker', $
                     '1\Config', $
                     '0\Load Configuration', $
                     '0\Image Size', $
                     '0\Image X Size', $
                     '0\Image Y Size', $
                     '0\Image Scale', $
                     '0\Extra Noise', $
                     '2\Last Config'], UVALUE='THE_MENU', /MBAR)

   base = widget_base(mainbase,/row)

   xsize=512
   ysize=512
   scale=0.7
   obscode='568'
   getobloc,obscode,obs

   win1 = widget_draw( base, XSIZE=xsize, YSIZE=xsize, RETAIN=2, $
                       /BUTTON_EVENTS, /MOTION_EVENTS, UVALUE='Window' )
   timerid = widget_base(base,row=1,uvalue='Timer')

   b1 = widget_base(base,/col)

   b2 = widget_base(b1,/row,/align_left)
   t1=widget_label(b2,value='File:')
   fnlabel = widget_label(b2,value='',/dynamic_resize)

   b2 = widget_base(b1,/row)
   t1=widget_label(b2,value='Center')
   cenlabel=widget_text(b2,value='00:00:00.0 +00:00:00', $
                        /editable,uvalue='Set Center')

   b2 = widget_base(b1,/row)
   t1=widget_label(b2,value='Marker')
   taglabel=widget_text(b2,value='00:00:00.0 +00:00:00', $
                        /editable,uvalue='Set Marker')

   b2 = widget_base(b1,/row)
   t1=widget_label(b2,value='Obsrvy')
   obslabel=widget_text(b2,value=obscode, $
                        /editable,uvalue='Set Observatory')

   b2 = widget_base(b1,/row)
   obsnameid=widget_label(b2,value=obs.name,/dynamic_resize)

   b2 = widget_base(b1,/row)
   t1=widget_label(b2,value='UT D/T')
   timelabel=widget_text(b2,value='auto', $
                        /editable,uvalue='Set Time')

   b2 = widget_base(b1,/row)
   b3 = widget_base(b2,/col)
   dummy=widget_label(b2,value='UT',/dynamic_resize)
   utid=widget_label(b2,value='',/dynamic_resize)

   b2 = widget_base(b1,/row)
   b3 = widget_base(b2,/col)
   dummy=widget_label(b2,value='Marker',/dynamic_resize)
   markerid=widget_label(b2,value='',/dynamic_resize)

   b2 = widget_base(b1,/row)
   b3 = widget_base(b2,/col)
   dummy=widget_label(b2,value='Airmass',/dynamic_resize)
   airmassid=widget_label(b2,value='',/dynamic_resize)

   b2 = widget_base(b1,/row)
   b3 = widget_base(b2,/col)
   dummy=widget_label(b2,value='Altitude',/dynamic_resize)
   altitudeid=widget_label(b2,value='',/dynamic_resize)

   b2 = widget_base(b1,/row)
   b3 = widget_base(b2,/col)
   dummy=widget_label(b2,value='Hour Angle',/dynamic_resize)
   haid=widget_label(b2,value='',/dynamic_resize)

   b2 = widget_base(b1,/row)
   b3 = widget_base(b2,/col)
   dummy=widget_label(b2,value='FOV',/dynamic_resize)
   fovid=widget_label(b2,value='',/dynamic_resize)
   dummy=widget_label(b2,value='arcsec',/dynamic_resize)

   b2 = widget_base(b1,/row)
   b3 = widget_base(b2,/col)
   dummy=widget_label(b2,value='Scale',/dynamic_resize)
   scaleid=widget_label(b2,value='',/dynamic_resize)
   dummy=widget_label(b2,value='arcsec/pixel',/dynamic_resize)

   b2 = widget_base(b1,/row)
   b3 = widget_base(b2,/col)
   dummy=widget_label(b2,value='Extra noise',/dynamic_resize)
   noiseid=widget_label(b2,value='0.0',/dynamic_resize)
   dummy=widget_label(b2,value='DN',/dynamic_resize)

   motionid=widget_label(b1,value='',/dynamic_resize)
   offsetid=widget_label(b1,value='',/dynamic_resize)
   coffsetid=widget_label(b1,value='',/dynamic_resize)

   state = ptr_new({ $

      ; Data and information in the widget
      autotime: 1, $
      filename: '', $
      fnpath: './', $
      horzmode: 0, $
      jd: systime(/julian,/ut), $
      obscode: obscode, $
      obslon: obs.lon, $
      obslat: obs.lat, $
      obsname: obs.name, $
      pastinfo: ptr_new(), $
      pimage: ptr_new(), $       ; pointer to the original image data
      posang: 0.0d0, $
      psynimage: ptr_new(), $
      psyninfo: ptr_new(), $
      noise: 0.0, $
      racen: 0.0d0, $
      deccen: 0.0d0, $
      ratag: 0.0d0, $
      dectag: 0.0d0, $
      scale: scale, $
      wcstype: -1, $       ; -1 - none loaded, 0 = Astrolib, 1= Buie
      xflip: 0, $
      xsize: xsize, $
      yflip: 0, $          ; never used
      ysize: ysize, $
      zenang: 0.0d0, $

      ; Widget ids
      airmassid: airmassid, $
      altitudeid: altitudeid, $
      cenlabel: cenlabel, $
      drawwin: win1, $           ; ID of main draw window
      fnlabel: fnlabel, $        ; ID for text widget to show file name
      fovid: fovid, $
      haid: haid, $
      markerid: markerid, $
      motionid: motionid, $
      noiseid:  noiseid, $
      obslabel: obslabel, $
      obsnameid: obsnameid, $
      offsetid: offsetid, $
      coffsetid: coffsetid, $
      scaleid: scaleid, $
      taglabel: taglabel, $
      timelabel: timelabel, $
      timerid: timerid, $
      utid:      utid, $

      mainbase: mainbase $       ; ID of top level base.

      })

   valid=1
   if config ne '' then finder_loadconfig,config,valid,state
   if not valid then print,'Config file ',config,' not valid.'

   ;Stash the state structure pointer.
   widget_control, mainbase, SET_UVALUE=state

   ;Realize the main base.
   widget_control, mainbase, /REALIZE

   ; Give control to the XMANAGER.
   xmanager, 'finder', mainbase, $
             EVENT_HANDLER='finder_eve',/NO_BLOCK, $
             GROUP_LEADER=mainbase, CLEANUP='finder_cleanup'

end