;+
; NAME:
;  obsnight
; PURPOSE:   (one line only)
;  Determine general details of a given night determined by Sun and Moon
; DESCRIPTION:
; CATEGORY:
;  Astronomy
; CALLING SEQUENCE:
;  obsnight,jd,obs,night
; INPUTS:
;  jd - Julian date for a time near midnight, string or double
;  obs - Observatory information, either an integer, string, or structure
; OPTIONAL INPUT PARAMETERS:
; KEYWORD INPUT PARAMETERS:
; OUTPUTS:
;  night - anonymous structure with information about the night
; KEYWORD OUTPUT PARAMETERS:
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
; PROCEDURE:
; MODIFICATION HISTORY:
;  2016/02/05, Written by Marc W. Buie, Southwest Research Institute
;-
pro obsnight,in_jd,in_obs,night

   self='obsnight: '
   if badpar(in_jd,[5,7],0,caller=self+'(jd) ',type=jdtype) then return
   if badpar(in_obs,[2,3,7,8],[0,1],caller=self+'(obs) ',type=obstype) then return

   if jdtype eq 7 then begin
      jd=jdparse(in_jd)
   endif else begin
      jd=in_jd
   endelse

   if obstype eq 8 then begin
      obs=in_obs
   endif else begin
      getobloc,in_obs,obs
   endelse

   ; Nearest midnight
   sunpos,jd,sunra,sundec,/radian
   am  = airmass(jd,sunra,sundec,obs.lat,obs.lon,alt=alt,lha=lha,lst=lst)
   hatojd,!dpi,sunra,lst,jd,jdlclmid ; jd of nearest local midnight
   lsidtim,jdlclmid,obs.lon,midlst       ; LST at local midnight
   jdofmid = float(long(jdlclmid+0.5d0))-0.5d0
   jdstr,jdofmid,100,thisdate
   jdstr,jdlclmid,-3,jdlclmids

   ; Hour angle of Sun at sunset, AT, NT, CT
   altoha,-18.0/!radeg,sundec,obs.lat,sunatha,sunattype
   altoha,-12.0/!radeg,sundec,obs.lat,sunntha,sunnttype
   altoha,-6.0/!radeg,sundec,obs.lat,sunctha,suncttype
   altoha,-0.5/!radeg,sundec,obs.lat,sunhorzha,sunhorztype

   ; JD of sunset/sunrise, AT, NT, CT
   jdatset  = jdlclmid - (!dpi-sunatha)/2.0d0/!dpi
   jdatrise = jdlclmid + (!dpi-sunatha)/2.0d0/!dpi
   jdntset  = jdlclmid - (!dpi-sunntha)/2.0d0/!dpi
   jdntrise = jdlclmid + (!dpi-sunntha)/2.0d0/!dpi
   jdctset  = jdlclmid - (!dpi-sunctha)/2.0d0/!dpi
   jdctrise = jdlclmid + (!dpi-sunctha)/2.0d0/!dpi
   jdsset   = jdlclmid - (!dpi-sunhorzha)/2.0d0/!dpi
   jdsrise  = jdlclmid + (!dpi-sunhorzha)/2.0d0/!dpi

   jdstr,jdsset,-2,jdssets
   jdstr,jdsrise,-2,jdsrises
   jdstr,jdatset,-2,jdatsets
   jdstr,jdatrise,-2,jdatrises
   jdstr,jdntset,-2,jdntsets
   jdstr,jdntrise,-2,jdntrises
   jdstr,jdctset,-2,jdctsets
   jdstr,jdctrise,-2,jdctrises

   ; Moon information, at midnight
   moonpos,jdlclmid,moonra,moondec,/radian
   mphase,jdlclmid,moonphase

   hatojd,!dpi,moonra,lst,jd,jdmoontran ; jd of nearest lunar transit
   altoha,-0.5/!radeg,moondec,obs.lat,moonhorzha,moonhorztype
   jdmset   = jdmoontran - (!dpi-sunhorzha)/2.0d0/!dpi
   jdmrise  = jdmoontran + (!dpi-sunhorzha)/2.0d0/!dpi

   jdstr,jdmset,-2,jdmsets
   jdstr,jdmrise,-2,jdmrises

   events=['CT','CT','NT','NT','AT','AT','Mid','Mrise','Mset','Srise','Sset']
   times=[jdctset,jdctrise,jdntset,jdntrise,jdatset,jdatrise, $
          jdlclmid,jdmrise,jdmset,jdsrise,jdsset]

   idx=sort(times)
   events=events[idx]
   times=times[idx]

   z=where(times ge jdsset and times le jdsrise,/null)
   events=events[z]
   times=times[z]
   nevents=n_elements(events)
   jdstr,times,-2,str

   night={ $
      utdates:   thisdate, $
      jdlclmid:  jdlclmid, $
      jdlclmids: jdlclmids, $
      jdatset:   jdatset, $
      jdatrise:  jdatrise, $
      jdntset:   jdntset, $
      jdntrise:  jdntrise, $
      jdctset:   jdctset, $
      jdctrise:  jdctrise, $
      jdsset:    jdsset, $
      jdsrise:   jdsrise, $
      jdatsets:  jdatsets, $
      jdatrises: jdatrises, $
      jdntsets:  jdntsets, $
      jdntrises: jdntrises, $
      jdctsets:  jdctsets, $
      jdctrises: jdctrises, $
      jdssets:   jdssets, $
      jdsrises:  jdsrises, $
      jdmsets:   jdmsets, $
      jdmrises:  jdmrises, $
      events:    events, $
      times:     str, $
      nevents:   nevents, $
      sunra:     sunra, $
      sundec:    sundec, $
      moonra:    moonra, $
      moondec:   moondec, $
      moonphase: moonphase $
      }


end
