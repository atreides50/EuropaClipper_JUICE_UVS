;+
; NAME:
;  appuldis
; PURPOSE:   (one line only)
;  Find the circumstances of an appulse between a star and a solar system object
; DESCRIPTION:
;  Given the ephemeris
;  The approximate time of the appulse must be within +/-30 minutes or this
;    will fail.
; CATEGORY:
;  Astronomy
; CALLING SEQUENCE:
;  appuldis,objcode,obscode,jd,ra,dec,jdmin,sep
; INPUTS:
;  objcode - Standard object code (see ephem.pro)
;  obscode - Standard observatory code or a structure with the observatory
;              information.
;  jd      - Approximate time of appulse
;  ra      - right ascension of the star, J2000
;  dec     - declination of the star, J2000
; OPTIONAL INPUT PARAMETERS:
; KEYWORD INPUT PARAMETERS:
;  ET      - Flag, if set, all times are in Ephemeris Time, default is UTC
;              This is most important for the output.  You can get away with
;              inputing either.
;  VERBOSE - Flag, if set, prints information about event to terminal
;  STARERR - Star position uncertainty (arcsec), default is 0.050 arcsec
; OUTPUTS:
;  jdmin   - Time of the minimum separation
;  sep     - Separation between star and object at jdmin (arcsec)
;                 If you get a negative number it means the search was not
;                 successful in finding a minimum near the input time.
; KEYWORD OUTPUT PARAMETERS:
;  info - Anonymous structure with auxillary information about the object
;            at the time of the minimum separation.
;           objname - Full name/designation of object
;           jd  - Time of close approach
;           hv  - Absolute magnitude of object
;           et  - Flag, set if time is ET
;           minsep - separate at close approach time (arcsec)
;           pa  - Position angle of object wrt star at minimum separation
;           sun - Heliocentric distance of object
;           earth - topocentric distance of object
;           phang - phase angle (degrees)
;           selong - solar elongation (degrees)
;           melong - lunar elongation (degrees)
;           mphase - Lunar phase
;           kmscale - scale on plane of sky in km/arcsec
;           oam    - Airmass of object at time of event
;           oalt   - object elevation (degrees)
;           oaz    - object azimuth, westward from south
;           salt   - solar elevation (degrees)
;           malt   - lunar elevation (degrees)
;           speed - projected speed of object relative to the star (km/sec)
;           rate  - projected speed of object ralative to the star (arcsec/hr)
;           diam1  - Diameter of object assuming 5% albedo (km)
;           diam2  - Diameter of object assuming 30% albedo (km)
;           chord1 - Maximum occultation duration assuming a 5% albedo size
;           chord2 - Maximum occultation duration assuming a 30% albedo size
;           angsha - Position angle of track on the plane of the sky, E of N
;           etime  - 1-sigma error in event time (seconds)
;           etrack - 1-sigma error in cross-track position (km)
;           coverage - Fraction of the 1-sigma cross track error that could
;                         be covered if track is centered on network
;           err    - 1-sigma ephemeris uncertainty for the object at the
;                       time of the close approach
;           errkm  - 1-sigma ephemeris uncertainty in km.
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
; PROCEDURE:
; MODIFICATION HISTORY:
;  Written by Marc W. Buie, Southwest Research Institute, 2015/03/07
;  2015/09/24, MWB, Added position angle output
;-
pro appuldis_separation,lun,objcode,obscode,jd,ra,dec,sep,pa,obspos

   ephem,jd,obscode,52,objcode,eph,pipe=lun,obspos=obspos ; ,/debug
   rao=trimrank(eph[0,0])
   deco=trimrank(eph[1,0])
;;oplot,[rao],[deco],psym=3
;print,rao,deco
;   sep1=angsep(ra,dec,rao,deco)*180.0d0/!dpi*3600.0
   astrd2sn,rao,deco,ra,dec,xi,eta,/arcsec
   pa=atan(eta,xi)*180.0d0/!dpi
   sep=sqrt(xi^2+eta^2)
;print,'app ',sep1,sep,sep1-sep

end

pro appuldis,objcode,in_obscode,jd,ra,dec,jdmin,sep,pa, $
       ET=et,INFO=info,VERBOSE=verbose,STARERR=starerr,PIPE=pipe

   self='appuldis: '
   if badpar(objcode,7,0,caller=self+'(objcode) ') then return
   if badpar(in_obscode,[2,3,7,8],[0,1],caller=self+'(obscode) ', $
                                  type=obstype) then return
   if badpar(jd,5,0,caller=self+'(jd) ') then return
   if badpar(ra,5,0,caller=self+'(ra) ') then return
   if badpar(dec,5,0,caller=self+'(dec) ') then return
   if badpar(et,[0,1,2,3],0,caller=self+'(ET) ',default=0) then return
   if badpar(verbose,[0,1,2,3],0,caller=self+'(VERBOSE) ',default=0) then return
   if badpar(starerr,[0,4,5],0,caller=self+'(STARERR) ',default=0.05) then return
   if badpar(pipe,[0,3,7],0,caller=self+'(PIPE) ',default='') then return
   if pipe eq '' then localpipe=1 else localpipe=0

   if et then begin
     print,self,'ET not implemented yet.'
     sep=-1.0
     return
   endif

   if obstype eq 8 then begin
      obs=in_obscode
      obscode=obs.obscode
      obspos=[obs.lat,-obs.lon,obs.alt]
   endif else begin
      if strn(in_obscode) ne '500' then begin
         getobloc,in_obscode,obs
         if obs.name eq 'unknown' then obscode='500' else obscode=in_obscode
      endif else begin
         obscode=in_obscode
      endelse
      getobloc,obscode,obs
      obspos=[obs.lat,-obs.lon,0.]
   endelse

   starerr=0.050 ; arcsec

;   pipe=''
   if localpipe then spawn,'geteph',unit=pipe

   jd_low  = jd - 2/24.0d0
   jd_high = jd + 2/24.0d0

   eps = 0.000003d0 ; days
   maxiter=40

   appuldis_separation,pipe,objcode,obscode,jd_low,ra,dec,sep_low,pa_low,obspos
   appuldis_separation,pipe,objcode,obscode,jd_high,ra,dec,sep_high,pa_high,obspos

;;vjd=[jd_low,jd_high]
;;vsep=[sep_low,sep_high]
;;vpa=[pa_low,pa_high]

   iter=0

   while jd_high-jd_low gt eps and iter lt maxiter do begin
      jd_new=(jd_high+jd_low)/2.0d0
      appuldis_separation,pipe,objcode,obscode,jd_new,ra,dec,sep_new,pa_new,obspos
;;vjd=[vjd,jd_new]
;;vsep=[vsep,sep_new]
;;vpa=[vpa,pa_new]
;print,iter,jd_low-jd,sep_low,jd_new-jd,sep_new,jd_high-jd,sep_high
      if iter eq 0 and (sep_low lt sep_new or sep_high lt sep_new) then begin
         if verbose then print,self,'No nearby appulse'
         sep=-1.0
         if localpipe then free_lun,pipe
         return
      endif
      if sep_low-sep_new le sep_high-sep_new then begin
         jd_high=jd_new
         sep_high=sep_new
      endif else begin
         jd_low=jd_new
         sep_low=sep_new
      endelse
      iter++
   endwhile

   jdmin=jd_new
   sep=sep_new
   pa=pa_new

;setwin,0
;;dx=vsep*cos(vpa/!radeg)
;;dy=vsep*sin(vpa/!radeg)
;plot,vjd-jdmin,vpa,psym=8
;oplot,dx,dy,psym=3
;plot,dx,dy,psym=8
;oplot,[dx[-1]],[dy[-1]],psym=8,color='0000ff'xl
;oplot,[0.,dx[-1]],[0.,dy[-1]],color='0070ff'xl

;setwin,1
;plot,vjd-jdmin,vsep,psym=8
;setwin,2
;plot,vjd-jdmin,dy,psym=8

   ; Collect some useful information about the object at the time of the appulse
   ephem,jdmin,obscode,72,objcode,eph,pipe=pipe,obspos=obspos ; ,/debug
   ssgeom,eph,sun,earth,phang,elong
   moonpos,jdmin,mra,mdec,/radian
   mphase,jdmin,mphase
   melong=sphdist(ra,dec,mra,mdec)*180.0d0/!dpi
   jdv=jdmin+[-1,1]*30.0/60.0/24.0d0
   ephem,jdv,obscode,52,objcode,eph,pipe=pipe,obspos=obspos ; ,/debug
   ra1=trimrank(eph[0,0])
   dec1=trimrank(eph[1,0])
   ra2=trimrank(eph[0,1])
   dec2=trimrank(eph[1,1])
   astrd2sn,ra1,dec1,ra,dec,xi1,eta1,/arcsec
   astrd2sn,ra2,dec2,ra,dec,xi2,eta2,/arcsec
   rate=sqrt((xi1-xi2)^2 + (eta1-eta2)^2) ; arcsec/hour
   kmscale = 1.0/(1.0/(earth*1.49598e8)*!radeg*3600.0) ; km/arcsec
   speed = rate*kmscale/3600.0 ; km/sec
   ephem,jdmin,obscode,11,objcode,eph,pipe=pipe,obspos=obspos
   err=eph[12,0]
   errkm=err*kmscale
   vdra=eph[10,0]
   vddec=eph[11,0]
   astrd2sn,ra+vdra,dec+vddec,ra,dec,vxi,veta,/arcsec
   vsha=[xi2,eta2]
   vsha=vsha/sqrt(total(vsha^2))
   vvar=[vxi,veta]
   vvar=vvar/sqrt(total(vvar^2))

   ; get the line of variations vector in the same quadrant as the shadow motion
   angsha=prival(atan(vsha[1],vsha[0]))*!radeg
   angvar=prival(atan(vvar[1],vvar[0]))*!radeg
   if abs(angsha-angvar) gt 90 and abs(angsha-angvar) lt 270 then vvar = -1*vvar

   ; get the components of error relative to shadow motion
   vpara = vsha*vvar
   epara = sqrt(total(vpara^2))*err ; arcsec
   eperp = sqrt(total((vvar*err)^2)-epara^2)

   epara = sqrt(epara^2 + starerr^2)
   eperp = sqrt(eperp^2 + starerr^2)

   etime = epara/rate*3600.0 ; seconds
   etrack = eperp*kmscale ; km

   ; success probability, crude
   reconlen = 1852.0 ; km, straight line from Oroville to Yuma
   coverage = reconlen/etrack

   spawn,'getinfo',unit=pipe2
   printf,pipe2,objcode
   obname=''
   readf,pipe2,obname,hv,gv,format='(a32,1x,f6.2,1x,f5.2)'
   free_lun,pipe2
   obname=strtrim(obname,2)
   diam1=hptodiam(hv,0.05)
   diam2=hptodiam(hv,0.30)
   chord1=diam1/speed
   chord2=diam2/speed

   if strn(obscode) eq '500' then begin
      salt=-100.
      malt=-100.
      oalt=-100.
      oam=1.0
      oaz=0.0
   endif else begin
;      obs.lat,obs.lon
      sunpos,jdmin,sra,sdec,/radian
      sam=airmass(jdmin,sra,sdec,obs.lat,obs.lon,alt=salt)
      mam=airmass(jdmin,mra,mdec,obs.lat,obs.lon,alt=malt)
      oam=airmass(jdmin,ra,dec,obs.lat,obs.lon,alt=oalt,az=oaz)
      salt=salt*!radeg
      malt=malt*!radeg
      oalt=oalt*!radeg
      oaz=oaz*!radeg
   endelse

   ; sky-plane rate of motion

   info={ $
      objname: obname, $
      jd:      jdmin, $
      hv:      hv, $
      et:      et, $
      minsep:  sep, $
      pa:      pa, $
      sun:     sun, $
      earth:   earth, $
      phang:   phang, $
      selong:  elong, $
      melong:  melong, $
      mphase:  mphase, $
      kmscale: kmscale, $
      oam:     trimrank(oam), $
      oalt:    oalt, $
      oaz:     oaz, $
      salt:    salt, $
      malt:    malt, $
      speed:   speed, $
      rate:    rate,  $
      diam1:   diam1, $
      diam2:   diam2, $
      chord1:  chord1, $
      chord2:  chord2, $
      angsha:  angsha, $ ; degrees
      etime:   etime, $ ; time error for event in seconds (along track)
      etrack:  etrack, $ ; track error for event in km (cross track)
      coverage: coverage, $ ; fraction of 1-sigma covered by RECON
      err:     err, $
      errkm:   errkm $
      }

   if verbose then begin
      jdstr,info.jd,0,jds
      if et then tid='ET' else tid='UT'
      print,'Appulse for object ',info.objname
      print,'Observatory code ',obscode,' - ',obs.name
      print,'Time of minimum separation ',jds,' ',tid
      print,'Minimum separation         ', $
            string(info.minsep,format='(f10.3)'),' arcsec'
      print,'Minimum separation         ', $
            string(info.minsep*kmscale,format='(f10.3)'),' km'
      print,'Position angle             ', $
            string(info.pa,format='(f10.1)'),' deg'
      print,'Heliocentric distance      ', $
            string(info.sun,format='(f10.3)'),' AU'
      print,'Topocentric distance       ', $
            string(info.earth,format='(f10.3)'),' AU'
      print,'Sky-plane scale at object  ', $
            string(kmscale,format='(f10.3)'),' km/arcsec'
       print,'Solar phase angle          ', $
            string(info.phang,format='(f8.1)'),'   deg'
      print,'Solar elongation           ', $
            string(round(info.selong),format='(i6)'),'     deg'
      print,'Lunar elongation           ', $
            string(round(info.melong),format='(i6)'),'     deg'
      print,'Lunar phase                ', $
            string(round(info.mphase*100),format='(i6)'),'%'
      if strn(obscode) ne '500' then begin
         print,'Object azimuth        ',info.oaz,' deg'
         print,'Object elevation      ',info.oalt,' deg'
         print,'Solar elevation       ',info.salt,' deg'
         print,'Lunar elevation       ',info.malt,' deg'
      endif
      print,'Position angle of track    ', $
            string(info.angsha,format='(f8.1)'),'   deg'
      print,'Object moving at           ', $
            string(info.speed,format='(f8.1)'),'   km/sec'
      print,'Object moving at           ', $
            string(info.rate,format='(f8.1)'),'   arcsec/hr'
      print,'Ephemeris uncertainty      ', $
            string(info.err,format='(f10.3)'),' arcsec'
      print,'Ephemeris uncertainty      ', $
            string(info.errkm,format='(f8.1)'),'   km'
      print,'Absolute magnitude         ', $
            string(info.hv,format='(f8.1)')
      print,'Diameter ( 5% albedo)      ', $
            string(info.diam1,format='(f8.1)'),'   km'
      print,'Diameter (30% albedo)      ', $
            string(info.diam2,format='(f8.1)'),'   km'
      print,'Max occultation ( 5%)      ', $
            string(info.chord1,format='(f8.1)'),'   sec'
      print,'Max occultation (30%)      ', $
            string(info.chord2,format='(f8.1)'),'   sec'
      print,'Event time error           ', $
            string(info.etime,format='(f8.1)'),'   sec'
      print,'Cross track error          ', $
            string(info.etrack,format='(f8.1)'),'   km'
      print,'1-sigma error coverage     ', $
            string(info.coverage,format='(f9.2)')
   endif

   if localpipe then free_lun,pipe

end
