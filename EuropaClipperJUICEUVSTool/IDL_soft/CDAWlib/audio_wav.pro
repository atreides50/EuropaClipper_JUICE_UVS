FUNCTION parse_display_attribute, buf, indlst, varlst

n_terms = 0

WHILE 1 DO BEGIN
       
    ; Check to make sure the term has the following form:
    ; y=varname[(t0,t1,..tn)]
    ; No Z terms.  Were not doing spectagrams !!
    ; IF STREGEX (terms [i], 'y=([a-zA-Z0-9]+)

    pos = STREGEX (buf, '^y=([a-zA-Z_0-9]+)', LENGTH=len, /SUBEXPR)
    
    ; Break out of the loop any errors
    IF pos [0] eq -1 THEN RETURN, 0

    ; Get the name of the variable to index
    var = STRMID (buf, pos [1], len [1])

    ; Eat the buf
    buf = STRMID (buf, len [0])

    ; Make sure buf is not used up. Otherwise quit.
    IF ~ buf THEN RETURN, 0

    ; Check to make sure the next character is a '('.  If it is then eat it.
    c = STRMID (buf, 0, 1)

    IF c ne '(' THEN RETURN, 0

    buf = STRMID (buf, 1)

    ; Make sure buf is not used up. Otherwise quit.
    IF ~ buf THEN RETURN, 0

    ind = INTARR (3)
    
    ind [*] = -1

    in = 0

    ; Get all indexes.  Max is 3.
    FOR cnt = 0, 2 DO BEGIN 

        ; Try to read a number
        pos = STREGEX (buf, '^[0-9]+', LENGTH=len)

        ; Check for success
        IF pos [0] eq -1 THEN RETURN, 0

        ; Read the index
        READS, STRMID (buf, 0, len), in

        ind [cnt] = in

        ; Eat the number
        buf = STRMID (buf, len)

        ; Make sure buf is not used up. Otherwise quit.
        IF ~ buf THEN RETURN, 0 

        ; Check if the next character is a comma.  If it's not then break
        ; out of the loop.
        c = STRMID (buf, 0, 1)

        IF c ne ',' THEN BREAK

        ; Eat the comma
        buf = STRMID (buf, 1)

        ; Make sure buf is not used up. Otherwise quit.
        IF ~ buf THEN RETURN, 0

    ENDFOR

    ; Check if the next character is a ')'.  If it is, then eat it.
    c = STRMID (buf, 0, 1)

    IF c ne ')' THEN RETURN, 0

    buf = STRMID (buf, 1)

    ; Made it to here.  Add what we found to variable and index arrays.   
    varlst = [varlst, var]
    indlst = [indlst, [[ind [0]], [ind [1]], [ind [2]]]]

    n_terms = n_terms + 1

    ; Check if there is any more input to parse.  
    ; If buf is empty then we are done.
    IF ~ buf THEN BREAK
    
    ; Check if the next character is a ','.  If it is, then eat it.
    ; Alas we have more work to do.
    c = STRMID (buf, 0, 1)

    IF c ne ',' THEN RETURN, 0

    buf = STRMID (buf, 1)

ENDWHILE

RETURN, n_terms

END

FUNCTION AUDIO_WAV, astruct, vname, RANGE=range, GIF=gif, $
                   TSTART=TSTART, TSTOP=TSTOP, REPORT=reportflag, DEBUG=debugflag


; Set reportflag to a default if not passed.
IF keyword_set(REPORT) THEN reportflag=1L ELSE reportflag=0L

; Determine the field number associated with the variable 'vname'
w = WHERE(tag_names(astruct) eq strupcase(vname),wc)
IF (wc eq 0) THEN BEGIN
  print,'ERROR=No variable with the name:',vname,' in param 1!' & RETURN,-1
ENDIF ELSE vnum = w[0]

; Verify the type of the first parameter and retrieve the data
a = size(astruct.(vnum))
IF (a[n_elements(a)-2] ne 8) THEN BEGIN
  print,'ERROR= 1st parameter to plot_images not a structure' & RETURN,-1
ENDIF ELSE BEGIN
  a = tagindex('DAT',tag_names(astruct.(vnum)))
  IF (a[0] ne -1) THEN idat = astruct.(vnum).DAT $
  ELSE BEGIN
    a = tagindex('HANDLE',tag_names(astruct.(vnum)))
    IF (a[0] ne -1) THEN handle_value,astruct.(vnum).HANDLE,idat $
    ELSE BEGIN
      print,'ERROR= 1st parameter does not have DAT or HANDLE tag' & RETURN,-1
    ENDELSE
  ENDELSE
ENDELSE

; Determine which variable in the structure is the 'Epoch' data and retrieve it
b = astruct.(vnum).DEPEND_0 & c = tagindex(b[0],tag_names(astruct))
d = tagindex('DAT',tag_names(astruct.(c)))
IF (d[0] ne -1) THEN edat = astruct.(c).DAT $
ELSE BEGIN
  d = tagindex('HANDLE',tag_names(astruct.(c)))
  IF (d[0] ne -1) THEN handle_value,astruct.(c).HANDLE,edat $
  ELSE BEGIN
    print,'ERROR= Time parameter does not have DAT or HANDLE tag' & RETURN,-1
  ENDELSE
ENDELSE

; Get some info about the data using the SIZE function.
idat_size = SIZE (idat, /STRUCTURE)

; Make sure we are working a valid data type.
IF ((idat_size.type eq 0) or (idat_size.type gt 6 and idat_size.type lt 12)) THEN BEGIN

  PRINT,'STATUS=datatype indicates that data is not plottable' 
  RETURN,-1

ENDIF

; Get the DISPLAY attribute
found_display = 0 

a = tagindex ('DISPLAY_TYPE', tag_names (astruct.(vnum)))
IF (a[0] ne -1) THEN BEGIN 
   b = SIZE (astruct.(vnum).DISPLAY_TYPE, /N_ELEMENTS)
   IF (b ne 0) THEN BEGIN
      display = STRCOMPRESS (astruct.(vnum).DISPLAY_TYPE, /REMOVE_ALL) 
      found_display = 1
   ENDIF 
ENDIF

; We should not have gotten here if there was no DISPLAY attribute.
; Flag the error and go home.
IF  (found_display eq 0) THEN BEGIN
    PRINT,'ERROR=Can not read the DISPLAY_TYPE attribute.' 
    PRINT,'STATUS=Can not read the DISPLAY_TYPE attribute. Can not create audio file.' 

    RETURN, -1
ENDIF

; Split the value recieved for DISPLAY_TYPE at the '>' character.  The presence indicates
; that the next part of the DISPLAY_TYPE will give a specific formula to use to
; reduce a multidemsional array to a single dimension.
dsp = STRSPLIT (display, '>', /EXTRACT)

IF  (N_ELEMENTS (dsp) ge 2) THEN BEGIN

    ; Extract a comma deliminated set of terms.  Each term will generate a new
    ; audio file.
    ; terms = STRSPLIT (dsp [1], ',', /EXTRACT)
    indlst = INTARR (1, 3)
    varlst = ['']

    n_terms = parse_display_attribute( dsp [1], indlst, varlst )
    
    IF  n_terms gt 0 THEN BEGIN

        indlst = indlst [1:*, *]
        varlst = varlst [1:*]

    ENDIF ELSE BEGIN
        PRINT,'ERROR=Can not parse extended display attributes' 
        PRINT,'STATUS=There is an error in the extended display attributes or they are ' + $
              'not appropiate for the audify display type.'
        RETURN, -1

    ENDELSE

    new_data = MAKE_ARRAY (idat_size.DIMENSIONS [idat_size.N_DIMENSIONS - 1], n_terms, TYPE=idat_size.TYPE)

    FOR i = 0, n_terms - 1 DO BEGIN
 
        ; Exteded display attributes can only reference the current variable
        IF  varlst [i] ne astruct.(vnum).VARNAME THEN BEGIN

            PRINT,'ERROR=Extended display attributes can not referance other variables.' 
            PRINT,'STATUS=Extended display attributes for audify can not referance other variables.' 

            RETURN, -1        
      
        ENDIF 

        ; Get the appropiate index array
        ind = REFORM (indlst [i, *])

        ; Remove unneeded indices.
        ind = ind [WHERE (ind ne -1)]

        ; Find the requested dimensionality
        dim = N_ELEMENTS (ind)

        ; Make sure our data supports this.
        IF  dim ne idat_size.N_DIMENSIONS - 1 THEN BEGIN

            PRINT,'ERROR=Mismatch between extended display type request and data dimesnion.' 
            PRINT,'STATUS=Mismatch between extended display type request and data dimesnion.'
            RETURN, -1

        ENDIF 

        ; Extract the data that we are interested in
        CASE dim OF
           1:  new_data [*, i]  = REFORM (idat [ind [0], *])
           2:  new_data [*, i]  = REFORM (idat [ind [0], ind [1], *])
           3:  new_data [*, i]  = REFORM (idat [ind [0], ind [1], ind [2], *])
        ENDCASE

    ENDFOR

    idat = new_data 

    n_wave_files = n_terms

ENDIF ELSE BEGIN 

    ; Make sure that we can create an audio file from the data.
    CASE idat_size.N_DIMENSIONS OF
      0   : BEGIN
               PRINT,'ERROR=Can not create audio file from single data point' 
               PRINT,'STATUS=Re-select longer time interval. Can not create audio file.' 
               RETURN, -1
            END

      1   : BEGIN
               
               n_wave_files = 1

               ; Make sure that we have data points for each time and vica versa.
    	       IF (N_ELEMENTS(idat) ne N_ELEMENTS(edat)) THEN BEGIN

                  print, 'STATUS=Re-select longer time interval; one value found for ', $
                         vname, ' and not useable.' 

                  RETURN, -1

    	       ENDIF

            END

;     2   : BEGIN
;
;           If we ever support multi-dimensional time series data (1 dimension with
;           multiple values), we are going to have transpose it.
;
;           END
           
      ELSE: BEGIN
               PRINT,'ERROR=Cannot create audio files for data with multiple dimensions' 
               RETURN, -1
            END
    ENDCASE

ENDELSE

; Determine the proper start and stop times of the audio file.

; default to data
tbegin = edat [0] 
tend   = edat [N_ELEMENTS (edat) - 1] 

; set tbegin
IF KEYWORD_SET (tstart) THEN BEGIN 
  tbegin = tstart & tbegin16 = tstart & tbegintt = tstart
  ; If tstart is a string, convert it
  a = SIZE (TSTART, /TYPE)
  IF (a eq 7) THEN BEGIN 
      split_ep = STRSPLIT (tstart, '.', /EXTRACT)
      ; Epoch
      tbegin   = ENCODE_CDFEPOCH (tstart)
      ; Epoch16
      tbegin16 = ENCODE_CDFEPOCH (tstart, /EPOCH16, MSEC=split_ep[1])
      ; TT2000
      tbegintt = ENCODE_CDFEPOCH (tstart, /TT2000, MSEC=split_ep[1]) 
  ENDIF
ENDIF

; set tend
IF KEYWORD_SET (tstop) THEN BEGIN
  tend = tstop & tend16 = tstop & tendtt = tstop
  ; If tstart is a string, convert it
  a = SIZE (tstop, /TYPE)
  IF (a eq 7) THEN BEGIN 
      split_ep = STRSPLIT (tstop, '.', /EXTRACT)
      ; Epoch
      tend   = ENCODE_CDFEPOCH (tstop)
      ; Epoch16
      tend16 = ENCODE_CDFEPOCH (tstop, /EPOCH16, MSEC=split_ep[1])
      ; TT2000
      tendtt = ENCODE_CDFEPOCH (tstop, /TT2000, MSEC=split_ep[1]) 
  ENDIF
ENDIF

; Set tbegin and tend to their final values.
ep16 = 0 & eptt=0
if (size(edat[0],/tname) eq 'DCOMPLEX')then begin 
    ep16 = 1
    tend = tend16 
    tbegin = tbegin16
endif

if (size(edat[0],/tname) eq 'LONG64')then begin 
    eptt = 1
    tend = tendtt 
    tbegin = tbegintt
endif

rbegin = 0L 
w = WHERE ((CDF_EPOCH_COMPARE (edat, tbegin) ge 0), wc)

IF  (wc gt 0) THEN rbegin = w [0]

rend = N_ELEMENTS (edat) - 1 
w = WHERE ((CDF_EPOCH_COMPARE (edat, tend) le 0), wc)

IF (wc gt 0) THEN rend = w [-1]

; Check for innapropiate data bounds.
IF  (rbegin ge rend) THEN BEGIN
    print, 'rbegin and end = ', rbegin, rend
    print,'STATUS=No data within specidied time range.' 
    RETURN, -1
ENDIF

found_vmin = 0

a = tagindex ('VALIDMIN', tag_names (astruct.(vnum)))
IF (a[0] ne -1) THEN BEGIN 
   b = size (astruct.(vnum).VALIDMIN, /N_ELEMENTS)
   IF (b ne 0) THEN BEGIN
      vmin = astruct.(vnum).VALIDMIN
      ;IF N_ELEMENTS (vmin) eq 1 THEN vmin = MAKE_ARRAY (n_wave_files, VALUE = vmin) 
      found_vmin = 1
   ENDIF
ENDIF

IF  (~ found_vmin) THEN BEGIN
    vmin = MAKE_ARRAY (n_wave_files, VALUE = -16000.0)
    PRINT,'WARNING=Unable to determine validmin for ', vname
ENDIF

found_vmax = 0

a = tagindex ('VALIDMAX', tag_names (astruct.(vnum)))
IF (a[0] ne -1) THEN BEGIN 
   b = SIZE (astruct.(vnum).VALIDMAX, /N_ELEMENTS)
   IF (b ne 0) THEN BEGIN
      vmax = astruct.(vnum).VALIDMAX 
      ;IF N_ELEMENTS (vmax) eq 1 THEN vmax = MAKE_ARRAY (n_wave_files, VALUE = vmax) 
      found_vmax = 1
   ENDIF 
ENDIF

IF  (~ found_vmax) THEN BEGIN
    vmax = MAKE_ARRAY (n_wave_files, VALUE = 16000.0)
    PRINT,'WARNING=Unable to determine validmax for ', vname   
ENDIF 

found_fill = 0 

a = tagindex ('FILLVAL', tag_names (astruct.(vnum)))
IF (a[0] ne -1) THEN BEGIN 
   b = SIZE (astruct.(vnum).FILLVAL, /N_ELEMENTS)
   IF (b ne 0) THEN BEGIN
      fill = astruct.(vnum).FILLVAL 
      found_fill = 1
   ENDIF 
ENDIF

IF  (~ found_fill) THEN BEGIN       
    fill = 0 ; figure out what this value should be
    PRINT,'WARNING=Unable to determine fill value for ', vname
ENDIF 

smin = vmin

a = tagindex ('SCALEMIN', tag_names (astruct.(vnum)))
IF (a[0] ne -1) THEN BEGIN 
   b = SIZE (astruct.(vnum).SCALEMIN, /N_ELEMENTS)
   IF (b eq 0) THEN smin = astruct.(vnum).SCALEMIN 
ENDIF

smax = vmax

a = tagindex ('SCALEMAX', tag_names (astruct.(vnum)))
IF (a[0] ne -1) THEN BEGIN
   b = SIZE (astruct.(vnum).SCALEMAX, /N_ELEMENTS)
   IF (b ne 0) THEN smax = astruct.(vnum).SCALEMAX 
ENDIF

; Select the correct time range.
mytime = edat [rbegin:rend]

; Create each file in turn.
FOR wave_file = 0, n_wave_files - 1 DO BEGIN 

    ; Select data points within the requested time range.
    mydata = REFORM (idat [rbegin:rend, wave_file])

    ; Reset data that is set to fillval to validmin. 
    w = WHERE (idat eq fill, wc)
    IF  (wc gt 0) THEN BEGIN 
        mydata [w] = vmin

    ENDIF

    ; w = WHERE (idat gt vmin [wave_file] and idat lt vmax [wave_file], wc)
    ; Reset any data below validmin to validmin
    w = WHERE (idat lt vmin, wc)
    IF  (wc gt 0) THEN BEGIN

        mydata [w] = vmin

    ENDIF

    ; Reset any data above validmax to validmax
    w = WHERE (idat gt vmax, wc)
    IF  (wc gt 0) THEN BEGIN

        mydata [w] = vmax

    ENDIF

    t0 = CDF_ENCODE_EPOCH (tbegin, EPOCH=2) 
    t1 = CDF_ENCODE_EPOCH (tend, EPOCH=2)

    ; file_name = STRING (FORMAT = '(A, "_", I3.3, "_", A, "_", A, ".wav")', gif, wave_file, t0, t1)
    file_name = STRING (FORMAT = '(A, "_", I3.3, ".wav")', gif, wave_file)

    minval = smin
    maxval = smax

    scaledata = -32768 + UINT (65535.0 * (mydata - minval) / (maxval - minval))
    
    IF (reportflag eq 1) THEN printf, 1, 'AUDIO=', file_name
   
    PRINT, 'AUDIO=', file_name

    write_wav, file_name, scaledata, 44100

ENDFOR

return, 0

END
