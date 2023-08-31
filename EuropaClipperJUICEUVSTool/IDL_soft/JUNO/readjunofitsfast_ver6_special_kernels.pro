pro readjunofitsfast_ver6_special_kernels,filename,output,meta_kernels,maps=maps,starthackpointer=starthackpointer,deadtime=deadtime,analog=analog,plots=plots

;Version 4 is an update from version 3 by Greathouse on 10/11/13
;This version will read in all the appropriate info with the latest LIMA build

; filename = name of the fits output from LIMA
; output = name of the struct that all the inforamtion will be returned under

;set the keyword /maps if you would like to retrieve the lima prepared maps and phd_maps

;If you want to know more info about the LIMA file scroll down past end of this code to see a full
;discription of the lima fits files.





;##########################################################################
;#  Here we get the SPK and CK kernel names to be printed onto the plots  #
;##########################################################################

cspice_kclear
cspice_furnsh, meta_kernels ;Loading the metakernel

print , meta_kernels

cspice_ktotal, 'TEXT', count
if (count eq 0) then begin
  print , '**** No tls kernels found ****'
  stop
endif
tls_kernel = ''

for i = 0, count-1 do begin
  cspice_kdata, i, 'TEXT', file, type, source, handle, found
  if (strmid(file, strlen(file) -3, 3) eq 'tls') then begin
    ss = strlen(file)
    res_splitting = STRSPLIT(file, '/')
    tls_kernel = strmid(file,res_splitting[-1],ss)
  endif

  if (strmid(file, strlen(file) -3, 3) eq 'tsc') then begin
    ss = strlen(file)
    res_splitting = STRSPLIT(file, '/')
    tsc_kernel = strmid(file,res_splitting[-1],ss)
  endif
endfor


;#########################################################################

res_splitting = STRSPLIT(filename, '/')
Lima_file = strmid(filename,res_splitting[-1],ss)

;#########################################################################






loadct,13
device,decompose=0

image=readfits(filename)  ;This reads in extension 0, detector image
if (keyword_set(plots)) then display,image

if (Keyword_set(maps)) then begin
  maps=readfits(filename,exten_no=1)
  phd_maps_alpha=readfits(filename,exten_no=7)
  phd_maps_star=readfits(filename,exten_no=8)
  phd_maps_stims=readfits(filename,exten_no=9)
endif

header=headfits(filename,exten=0)             ;this reads in the header for extension 4 (where frame data resisdes
truehack=double(strmid(header(where(strcmp(header,'HACKCLCK',8))),16,14))

header=headfits(filename,exten=4)             ;this reads in the header for extension 4 (where frame data resisdes
if (fxpar(header,'naxis2') gt 0) then begin   ;This is just testing if any frame data exists
  ftab_ext_juno,filename,[1,2],RECV_TIME,FRAME_DATA,exten_no=4
  print,'got here'
  temp=frame_data[0:*:3,*]*2.^16+frame_data[1:*:3,*]*2.^8+frame_data[2:*:3,*]
  frame_data=temp
  temp=0.
  print,'got here'
  ftab_ext_juno, filename,[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19],FRAME_COUNTER,SC_RCVD_TIME,FIRST_TIMEHACK,LAST_TIMEHACK,SC_TIME_FIRST_HACK,SC_TIME_LAST_HACK,FRAME_QUALITY,FRAME_TAG,FINAL_FRAME,QUALITY_FLAG,MEMORY_SIDE,HACK_RATE,NUM_TIMEHACKS,FRMSUM,CHKSUM,TYPE,CLOCK_PERIOD,NUM_ACQS,EXPECTED,exten_no=2
  ftab_ext_juno, filename,[1,2], POSITION_NUM, POSITION_TIME, exten_no=3
  if (keyword_set(analog)) then ftab_ext_juno,filename,[1,2],ANA_SCUT_TIME,ANA_COUNT_RATE,exten_no=5
  ftab_ext_juno, filename,[1,2,3],DIG_HACK_TIME,DIG_SCUT_TIME,DIG_COUNT_RATE,exten_no=6
  ftab_ext_juno, filename,[1,2,57,126],hk_sclk_time,hk_hack_time,hvps_setpoint,debug_array,exten_no=10
  ftab_ext_juno, filename,[1,31],hk_sclk_time_ext_11,hv_level,exten_no=11


;the angle reported in the debug array is an angular count down to the time when UVS should perform its mirror moves.
;That time is hopefully set to 90 degrees after UVS nadir.  Thus, to calculate the nadir time for UVS (which is 180 degrees off of 
;spacecraft nadir) you need to subtract 90 degrees from the nadir angle (debug array) or add 270 degrees.  Note also that the angle is
;a count down to zero.  Thus angle_till_uvs_nadir is a countdown to the actual time for UVS nadir look.

;  angle_till_uvs_nadir=((debug_array[8,*]*256.+debug_array[9,*])*360./65536.+270.) mod 360
;  it actually looks like the nadir pulse is the true nadir pulse not tampered with by UVS, so when UVS sees Jupiter 
; it is -180 spacecraft nadir
  angle_till_uvs_nadir=((debug_array[8,*]*256.+debug_array[9,*])*360./65536.+180.) mod 360



  if (keyword_set(deadtime)) then begin
	  deadtime_fact=(1.-dig_count_rate*1.2e-6)^(-1)
  endif

	  s=size(first_timehack,/dim)
	  dig_point_starthack=dblarr(s[0])
	  dig_point_starthack=lonarr(s[0])
;	  dig_point_starthack2=fltarr(s[0])
	  s2=size(dig_hack_time,/dim)
  if (keyword_set(starthackpointer)) then begin
    
	  ;the current version of lima leaves out the first hack from every frame within the dig_hack_time array.  This will probably change in the future.  If that is the case then I will have to shift by 1*2^hack_rate[i] only at the begining of each acquisition instead of every frame
    ;	  t1=systime(1)
    ;		  dig_point_starthack2[0]=where(first_timehack[0]+1*2^hack_rate[0] eq dig_hack_time)    ;i would like to time this to see how long it really takes
    ;	  for i=1,s[0]-1 do begin
    ;		  dig_point_starthack2[i]=where(first_timehack[i]+1*2^hack_rate[i] eq dig_hack_time)    ;i would like to time this to see how long it really takes
    ;;   This took 147 sec to run
    ;	  endfor
    ;	  print,'slow way to do it takes = ', systime(1)-t1


	  t=systime(1)
		  dig_point_starthack[0]=where(first_timehack[0]+1*2^hack_rate[0] eq dig_hack_time[0:32768])  ;why do i ned to offset first_timehack here by 1?
		  
	  for i=1,s[0]-1 do begin
;		  dig_point_starthack[i]=dig_point_starthack[i-1]+where(first_timehack[i]+1*2^hack_rate[i] eq dig_hack_time[dig_point_starthack[i-1]:min([long(dig_point_starthack[i-1]+32768),s2[0]-1])])

		foo=where(first_timehack[i] eq dig_hack_time[dig_point_starthack[i-1]:min([long(dig_point_starthack[i-1]+32768),s2[0]-1])],nfoo)
		
		; VH-Note to himself: When starting a new tag obs, dig_point_starthack points, in the digital list, toward the second hack of the first frame of that new sequence. 
		; This is also the case when there is a gap in frame counter and/or a discontinuity in hacks (e.g. data dropout)
		; Otherwise, when the frames are contigous, dig_point_starthack points, in the digital list, toward the first hack of the frames.
		
		if (~nfoo) then begin
		  ;if hack_rate[i] eq 9 then stop
		  foo=where(first_timehack[i]+1L*2^hack_rate[i] eq dig_hack_time[dig_point_starthack[i-1]:min([long(dig_point_starthack[i-1]+32768),s2[0]-1])],nfoo)
		endif
		dig_point_starthack[i]=dig_point_starthack[i-1]+foo
		
		;if hack_rate[i] eq 9 then stop
		
		;if first_timehack[i] ne dig_hack_time[dig_point_starthack[i]] then stop , 'error match of the first hack'
		
;This took 0.2612 sec to run  (562 times faster than the dumb way)
	  endfor
	print,'time to find the digital points for starthacks fast = ',systime(1)-t
  endif

  if keyword_set(maps) then begin
    output = {image:image,maps:maps,phd_maps_alpha:phd_maps_alpha,phd_maps_star:phd_maps_star, $
       phd_maps_stims:phd_maps_stims, $
       FRAME_COUNTER:FRAME_COUNTER,SC_RCVD_TIME:SC_RCVD_TIME,FIRST_TIMEHACK:FIRST_TIMEHACK, $
       LAST_TIMEHACK:LAST_TIMEHACK,SC_TIME_FIRST_HACK:SC_TIME_FIRST_HACK,dig_point_starthack:dig_point_starthack,  $
       SC_TIME_LAST_HACK:SC_TIME_LAST_HACK,FRAME_QUALITY:FRAME_QUALITY,FRAME_TAG:FRAME_TAG,  $
       FINAL_FRAME:FINAL_FRAME,QUALITY_FLAG:QUALITY_FLAG,MEMORY_SIDE:MEMORY_SIDE,HACK_RATE:HACK_RATE, $
       NUM_TIMEHACKS:NUM_TIMEHACKS,FRMSUM:FRMSUM,CHKSUM:CHKSUM,TYPE:TYPE,CLOCK_PERIOD:CLOCK_PERIOD, $
       NUM_ACQS:NUM_ACQS,EXPECTED:EXPECTED,POSITION_NUM:POSITION_NUM,POSITION_TIME:POSITION_TIME, $
       RECV_TIME:RECV_TIME,FRAME_DATA:FRAME_DATA,DIG_SCUT_TIME:DIG_SCUT_TIME,DIG_HACK_TIME:DIG_HACK_TIME, $
       DIG_COUNT_RATE:DIG_COUNT_RATE,truehack:truehack, $
       ANA_SCUT_TIME:ANA_SCUT_TIME,ANA_COUNT_RATE:ANA_COUNT_RATE,hk_sclk_time:hk_sclk_time,$
	hk_hack_time:hk_hack_time,hvps_setpoint:hvps_setpoint,hk_sclk_time_ext_11:hk_sclk_time_ext_11,$
	hv_level:hv_level,DEADTIME_FACT:DEADTIME_FACT,debug_array:debug_array,angle_till_uvs_nadir:angle_till_uvs_nadir} 
  endif else begin
  if (keyword_set(deadtime)) then begin
     If (keyword_set(analog)) then begin
     output = {image:image, $
	FRAME_COUNTER:FRAME_COUNTER,SC_RCVD_TIME:SC_RCVD_TIME,FIRST_TIMEHACK:FIRST_TIMEHACK, $
	LAST_TIMEHACK:LAST_TIMEHACK,SC_TIME_FIRST_HACK:SC_TIME_FIRST_HACK,dig_point_starthack:dig_point_starthack,  $
	SC_TIME_LAST_HACK:SC_TIME_LAST_HACK,FRAME_QUALITY:FRAME_QUALITY,FRAME_TAG:FRAME_TAG,  $
	FINAL_FRAME:FINAL_FRAME,QUALITY_FLAG:QUALITY_FLAG,MEMORY_SIDE:MEMORY_SIDE,HACK_RATE:HACK_RATE, $
	NUM_TIMEHACKS:NUM_TIMEHACKS,FRMSUM:FRMSUM,CHKSUM:CHKSUM,TYPE:TYPE,CLOCK_PERIOD:CLOCK_PERIOD, $
	NUM_ACQS:NUM_ACQS,EXPECTED:EXPECTED,POSITION_NUM:POSITION_NUM,POSITION_TIME:POSITION_TIME, $
	RECV_TIME:RECV_TIME,FRAME_DATA:FRAME_DATA,DIG_SCUT_TIME:DIG_SCUT_TIME,DIG_HACK_TIME:DIG_HACK_TIME, $
	DEADTIME_FACT:DEADTIME_FACT,DIG_COUNT_RATE:DIG_COUNT_RATE,truehack:truehack,$
	DIG_COUNT_RATE:DIG_COUNT_RATE,truehack:truehack,$
	ANA_SCUT_TIME:ANA_SCUT_TIME,ANA_COUNT_RATE:ANA_COUNT_RATE,hk_sclk_time:hk_sclk_time,$
	hk_hack_time:hk_hack_time,hvps_setpoint:hvps_setpoint,hk_sclk_time_ext_11:hk_sclk_time_ext_11,$
        hv_level:hv_level,debug_array:debug_array,angle_till_uvs_nadir:angle_till_uvs_nadir} 
     endif else begin
    output = {image:image, $
       FRAME_COUNTER:FRAME_COUNTER,SC_RCVD_TIME:SC_RCVD_TIME,FIRST_TIMEHACK:FIRST_TIMEHACK, $
       LAST_TIMEHACK:LAST_TIMEHACK,SC_TIME_FIRST_HACK:SC_TIME_FIRST_HACK,dig_point_starthack:dig_point_starthack,  $
       SC_TIME_LAST_HACK:SC_TIME_LAST_HACK,FRAME_QUALITY:FRAME_QUALITY,FRAME_TAG:FRAME_TAG,  $
       FINAL_FRAME:FINAL_FRAME,QUALITY_FLAG:QUALITY_FLAG,MEMORY_SIDE:MEMORY_SIDE,HACK_RATE:HACK_RATE, $
       NUM_TIMEHACKS:NUM_TIMEHACKS,FRMSUM:FRMSUM,CHKSUM:CHKSUM,TYPE:TYPE,CLOCK_PERIOD:CLOCK_PERIOD, $
       NUM_ACQS:NUM_ACQS,EXPECTED:EXPECTED,POSITION_NUM:POSITION_NUM,POSITION_TIME:POSITION_TIME, $
       RECV_TIME:RECV_TIME,FRAME_DATA:FRAME_DATA,DIG_SCUT_TIME:DIG_SCUT_TIME,DIG_HACK_TIME:DIG_HACK_TIME, $
       DEADTIME_FACT:DEADTIME_FACT,DIG_COUNT_RATE:DIG_COUNT_RATE,truehack:truehack,hk_sclk_time:hk_sclk_time,$
        hk_hack_time:hk_hack_time,hvps_setpoint:hvps_setpoint,hk_sclk_time_ext_11:hk_sclk_time_ext_11,$
        hv_level:hv_level,debug_array:debug_array,angle_till_uvs_nadir:angle_till_uvs_nadir,$
        tsc_kernel: tsc_kernel , TLS_Kernel: tls_kernel , Lima_file: Lima_file}
     endelse
  endif else begin
    output = {image:image, $
       FRAME_COUNTER:FRAME_COUNTER,SC_RCVD_TIME:SC_RCVD_TIME,FIRST_TIMEHACK:FIRST_TIMEHACK, $
       LAST_TIMEHACK:LAST_TIMEHACK,SC_TIME_FIRST_HACK:SC_TIME_FIRST_HACK,dig_point_starthack:dig_point_starthack,  $
       SC_TIME_LAST_HACK:SC_TIME_LAST_HACK,FRAME_QUALITY:FRAME_QUALITY,FRAME_TAG:FRAME_TAG,  $
       FINAL_FRAME:FINAL_FRAME,QUALITY_FLAG:QUALITY_FLAG,MEMORY_SIDE:MEMORY_SIDE,HACK_RATE:HACK_RATE, $
       NUM_TIMEHACKS:NUM_TIMEHACKS,FRMSUM:FRMSUM,CHKSUM:CHKSUM,TYPE:TYPE,CLOCK_PERIOD:CLOCK_PERIOD, $
       NUM_ACQS:NUM_ACQS,EXPECTED:EXPECTED,POSITION_NUM:POSITION_NUM,POSITION_TIME:POSITION_TIME, $
       RECV_TIME:RECV_TIME,FRAME_DATA:FRAME_DATA,DIG_SCUT_TIME:DIG_SCUT_TIME,DIG_HACK_TIME:DIG_HACK_TIME, $
       DIG_COUNT_RATE:DIG_COUNT_RATE,truehack:truehack,hk_sclk_time:hk_sclk_time,$
        hk_hack_time:hk_hack_time,hvps_setpoint:hvps_setpoint,hk_sclk_time_ext_11:hk_sclk_time_ext_11,$
        hv_level:hv_level,debug_array:debug_array,angle_till_uvs_nadir:angle_till_uvs_nadir}
  endelse
  endelse
endif else begin
  print,'No acquisitions in fits file=',filename
endelse


return
end

;Below this you can read about the extensions and what each extension contains.


;>rdfits_struct,filename,test

;Dimensions of the 11 different extensions of the JUNO UVS LIMA output


   ;Extension = 0
      ;Is the integrated histogram image of all data contained in the .FITS file
      ;   HDR0            STRING    Array[113]
      ;   IM0             LONG      Array[2048, 256]


   ;Extension = 1
      ;Is the spatial x spatial(actually temporal due to spin)  maping of spin onto the sky
      ;   HDR1            STRING    Array[119]
      ;   IM1             LONG      Array[300, 256, 155]

   ;Extension = 2
      ;   HDR2            STRING    Array[183]
      ;   TAB2            BYTE      Array[185, 462]
      ;>ftab_help,filename,exten_no=2
      ;Extension No: 2
      ;FITS ASCII Table Header: 
      ;Extension Name: Frame List
      ;Version:            1
      ;Number of rows: 463
      ; 
      ;Field      Name               Unit           Format     Column
      ;1   FRAME_COUNTER                         I5             1
      ;2   SC_RCVD_TIME         s                D14.3          6
      ;3   FIRST_TIMEHACK                        I10           20
      ;4   LAST_TIMEHACK                         I10           30
      ;5   SC_TIME_FIRST_HACK   s                D14.3         40
      ;6   SC_TIME_LAST_HACK    s                D14.3         54
      ;7   FRAME_QUALITY                         I3            68
      ;8   FRAME_TAG                             I5            71
      ;9   FINAL_FRAME                           I1            76
      ;10   QUALITY_FLAG                          I3            77
      ;11   MEMORY_SIDE                           I1            80
      ;12   HACK_RATE                             I2            81
      ;13   NUM_TIMEHACKS                         I5            83
      ;14   FRMSUM                                I8            88
      ;15   CHKSUM                                I8            96
      ;16   TYPE                                  I2           104
      ;17   CLOCK_PERIOD                          I10          106
      ;18   NUM_ACQS                              I5           116
      ;19   EXPECTED                              I1           121
      ;20   FILE                                  A64          122

   ;Extension = 3
      ;   HDR3            STRING    Array[127]
      ;   TAB3            BYTE      Array[17, 8]
      ;>ftab_help,filename,exten_no=3
      ;Extension No: 3
      ;FITS ASCII Table Header: 
      ;Extension Name: Scan Mirror Positions
      ;Version:            1
         ;Number of rows: 8
         ; 
         ;Field      Name               Unit           Format     Column
         ; 
         ;    1   POSITION_NUM                          I3             1
         ;    2   TIME                                  D14.3          4   

   ;Extension = 4
      ;   HDR4            STRING    Array[122]
      ;   TAB4            BYTE      Array[98306, 463]
      ;>ftab_help,filename,exten_no=4
         ;Extension No: 4
         ;FITS Binary Table Header
         ;Size of Table Array: 98306 by 463
         ;Extension Name:   Raw Frame Data
         ; 
         ;Field       Name Unit   Frmt Null Comment
         ; 
         ;    1  RECV_TIME           D       frame spacecraft received time 
         ;    2 FRAME_DATA      98298B       raw frame data 

   ;Extension = 5
      ;   HDR5            STRING    Array[123]
      ;   TAB5            BYTE      Array[12, 36880]
      ;>ftab_help,filename,exten_no=5
         ;Extension No: 5
         ;FITS Binary Table Header
         ;Size of Table Array: 12 by 36880
         ;Extension Name:   Analog Count Rates
         ; 
         ;Field       Name Unit Frmt Null Comment
         ; 
         ;    1  SCUT_TIME         D       Spacecraft UTC (seconds) 
         ;    2 COUNT_RATE   Hz    J       Count rate for the interval (Hz) 

   ;Extension = 6
      ;   HDR6            STRING    Array[126]
      ;   TAB6            BYTE      Array[16, 2699553]
      ;>ftab_help,filename,exten_no=6
         ;Extension No: 6
         ;FITS Binary Table Header
         ;Size of Table Array: 16 by 2699553
         ;Extension Name:   Digital Count Rates
         ; 
         ;Field       Name Unit Frmt Null Comment
         ; 
         ;    1  HACK_TIME         J       Hack time at the start of the interval 
         ;    2  SCUT_TIME    s    D       Spacecraft UTC (seconds) 
         ;    3 COUNT_RATE   Hz    J       Count rate for the interval (Hz) 

   ;Extension = 7       ;Lyman Alpha PHDs
      ;Is the spatial(ie. temporal converts to spatial due to rotation) variation of the Lyman Aplha photon PHDs. 
      ;   HDR7            STRING    Array[124]
      ;   IM7             LONG      Array[300, 17, 89]
      ;>ftab_help,filename,exten_no=7

   ;Extension = 8       ;stellar PHDs
      ;Is the spatial(ie. temporal converts to spatial due to rotation) variation of the Stellar photon PHDs. 
      ;   HDR8            STRING    Array[124]
      ;   IM8             LONG      Array[300, 17, 89]
      ;>ftab_help,filename,exten_no=8

   ;Extension = 9       ;Stim PHDs
      ;Is the spatial(ie. temporal converts to spatial due to rotation) variation of the Stim event PHDs. 
      ;   HDR9            STRING    Array[124]
      ;   IM9             LONG      Array[300, 17, 89]
      ;>ftab_help,filename,exten_no=9

   ;Extension = 10 
      ;   HDR10            STRING    Array[485]
      ;   TAB10             BYTE     Array[766, 1844]
      ;>ftab_help,filename,exten_no=10
	;FITS file: UVS_ENG_434589840_2013283_V01_science.FIT
	;Extension No: 10
	;FITS Binary Table Header
	;Size of Table Array: 766 by 1844
	;Extension Name:   Housekeeping Data
	; 
	;Field                 Name Unit Frmt Null Comment
	 
	;    1            SCLK_TIME         D       Spacecraft clock (seconds since epoch) 
        ;    2            HACK_TIME         J       Instrument hack time 
	;    3             PACK_CNT         I       16-bit packet counter 
        ;    4          PACKET_DATA      340B       Raw HK packet (340 bytes) 
	;    5           INST_STATE         B       Instrument State (0=off, 1=checkout, 2=safe, 3=
        ;    6        SAFETY_ACTIVE         B       1=safety active 
        ;    7          LAST_SAFETY         B       Last safety (0=none) 
        ;    8          LVPS_STATUS         B       Power status for each LVPS, 1=active 
	;    9          HVPS_STATUS         B       Power status for each HVPS, 1=active 
        ;   10         DETECTOR_PWR         B       Power status of detector, 1=on 
        ;   11         TURN_OFF_REQ         B       1=request instrument shutdown by s/c 
        ;   12           WPA_DRIVEN         B       1=WPA activated 
        ;   13           WPA_SWITCH         B       1=WPA stroke switch activated 
	;   14            HVPS_SAFE         B       Safing status for each HVPS, 1=safing plug inst
        ;   15         RST_ACT_SAFE         B       Resettable actuator safing plug status, 1=insta
        ;   16     NON_RST_ACT_SAFE         B       Non-resettable actuator safing plus status, 1=i
        ;   17               SmInit         B       Scan Mirror movement control initialized: 1 = i
        ;   18         SCAN_MRR_HTR         B       Status of scan mirror heater, 1=on 
        ;   19          OAP_MRR_HTR         B       Status of the OAP mirror heater, 1=on 
        ;   20          GRT_MRR_HTR         B       Status of the grating mirror heater, 1=on 
        ;   21       CMD_LAST_CYCLE         B       1=command received during last cycle 
        ;   22           T_SYNC_MSG         B       1=valid time sync message received during last 
        ;   23         T_SYNC_PULSE         B       1=valid time sync pulse received during last cy
        ;   24         CRIT_TC_PEND         B       1=critical telecommand pending 
        ;   25            TC_STATUS         B       Instrument commanding input wait status: 1 - pr
        ;   26        CMDS_ACCEPTED         B       Modulo 2^8 count of commands accepted 
        ;   27        CMDS_REJECTED         B       Modulo 2^8 count of commands rejected 
        ;   28        CMDS_EXECUTED         B       Modulo 2^8 count of commands executed 
        ;   29      TIME_MSGS_RECVD         B       Modulo 2^8 count of time messages received 
        ;   30    TIME_PULSES_RECVD         B       Modulo 2^8 count of time pulses received 
        ;   31     NADIR_MSGS_RECVD         B       Modulo 2^8 count of nadir messages received 
        ;   32      LAST_ACCEPT_CMD         B       Opcode of last accepted command 
	;   33      LAST_FAILED_CMD         B       Opcode of last failed command 
        ;   34         LAST_FAILURE         B       Last failure code command/execution 
        ;   35     CRIT_CMD_TIMEOUT         B       Remaining timeout for a critical command 
	;   36          SCI_PKT_HDR         J       Header of the most recently acquired science pa
	;   37          SCI_QUALITY         B       Quality byte of the most recent science acquisi
        ;   38          SCI_PKT_TAG         I       Tag bytes of most recent science acquisition 
        ;   39    DETECTOR_DOOR_POS         B       0=illegal, 1=not open, 2=open, 3=illegal 
        ;   40    APERTURE_DOOR_POS         B       0=error, 1=closed, 2=open, 3=between 
        ;   41             HACKRATE         B       0=1ms, 1=2ms, ... 9=512ms 
	;   42       HVPS_COMMANDED         B       Commanded state of HVPS 1 and 2, 1=on 
	;   43         HVPS_LIMITED         B       1=HVPS limited due to high countrate 
        ;   44    HOT_PIXEL_MASKING         B       1=hot pixel masking (hardware) active 
	;   45         SCI_OVERFLOW         B       1=overflow occured in high speed science transf
	;   46              ACQ_MEM         B       0=side A, 1=side B 
        ;   47        DETECTOR_STIM         B       0=STIM off, 1=STIM on 
        ;   48      ACQ_EVT_POINTER         I       Most recent value of the h/w pixel list pointer
        ;   49     FIRST_COUNT_HACK         I       Value of the timehack counter at the first coun   
        ;   50      RAW_EVENT_COUNT         J       Current value of the hardware detector analog e
        ;   51       MAX_EVENT_RATE         J       Maximum digital unmasked event rate in the last
	;   52        MAX_MASK_RATE         J       Maximum digital masking rate in the last HK cyc
	;   53          ACQ_TIMEOUT         J       Remianing time (sec) of acquisiton timeout coun
	;   54 LAST_ACQ_COMPLETE_TI         J       Time of last acquisition completion 
        ;   55  LOWER_DISCRIMINATOR         B       Pulse height (0-31) 
        ;   56  UPPER_DISCRIMINATOR         B       Pulse height (0-31) 
	;   57        HVPS_SETPOINT         D       DAC counts 
        ;   58   HVPS_LIMIT_TIMEOUT         B       Remaining HVPS limit timeout in cycles 
        ;   59      MAX_MCP_VOLTAGE         D       Maximum MCP voltage in this HK reporting period
        ;   60      MIN_MCP_VOLTAGE         D       Minimum MCP voltage in this HK reporting period
        ;   61    MAX_ANODE_VOLTAGE         D       Maximum anode voltage in this HK reporting peri
        ;   62    MIN_ANODE_VOLTAGE         D       Minimum anode voltage in this HK reporting peri
        ;   63    MAX_STRIP_CURRENT         D       Maximum strip current in this HK reporting peri
        ;   64    MIN_STRIP_CURRENT         D       Minimum strip current in this HK reporting peri
	;   65              P7_VOLT         D       ADC counts, range matching measure voltage 
        ;   66              N7_VOLT         D       ADC counts, range matching measure voltage 
        ;   67              P5_VOLT         D       ADC counts, range matching measure voltage 
        ;   68              N5_VOLT         D       ADC counts, range matching measure voltage 
        ;   69            P3_3_VOLT         D       ADC counts, range matching measure voltage 
        ;   70            P1_8_VOLT         D       ADC counts, range matching measure voltage 
        ;   71            P1_5_VOLT         D       ADC counts, range matching measure voltage 
        ;   72         REF_0_3_VOLT         D       ADC counts, range matching measure voltage 
	;   73         REF_2_7_VOLT         D       ADC counts, range matching measure voltage 
        ;   74     SEQUENCER_ACTIVE         B       1=scan mirror sequencer active 
        ;   75     CURRENT_POSITION         B       Current scan mriror position 
        ;   76    END_SWTICHES_STAT         B       1=switch closed 
        ;   77       TIME_TO_ZENITH         B       Remaining time to zenith in sec*2 
        ;   78        CURRENT_PHASE         B       Current phsae within scan table 
        ;   79       REM_PHASE_TIME         I       Time remaining in current phase in sec*2 
        ;   80       ACT_SEQ_OFFSET         B       Offset within the current sequence phase 
        ;   81         ACT_SEQ_STEP         B       Step within the current sequence phase 
        ;   82        ACT_SEQ_CYCLE         B       Cycles within the current sequence step phase 
        ;   83            REM_DWELL         B       Remaining number of dwell cycles at the current
	;   84 SCAN_MRR_HTR_SETPOIN         D       ADC counts 
        ;   85 OAP_MRR_HTR_SETPOINT         D       ADC counts 
        ;   86 GRATING_HTR_SETPOINT         D       ADC counts 
        ;   87 SCAN_MRR_PRIMARY_TMP         D       ADC counts 
        ;   88 SCAN_MRR_SECONDARY_T         D       ADC counts 
        ;   89  OAP_MRR_PRIMARY_TMP         D       ADC counts 
        ;   90 OAP_MRR_SECONDARY_TM         D       ADC counts 
        ;   91  GRATING_PRIMARY_TMP         D       ADC counts 
        ;   92 GRATING_SECONDARY_TM         D       ADC counts 
        ;   93         CDH_ELEC_TMP         D       ADC counts 
        ;   94            HVPS_TEMP         D       ADC counts 
        ;   95            LVPS_TEMP         D       ADC counts 
        ;   96     DETECTOR_BDY_TMP         D       ADC counts 
        ;   97    DETECTOR_ELEC_TMP         D       ADC counts 
        ;   98            SMIB_TEMP         D       ADC counts 
        ;   99         CHASSIS_TEMP         D       ADC counts 
        ;  100    HVPS_LIMIT_CYCLES         B       Number of remaining cycles in this acquisition 
        ;  101          TEMP_SAFETY         B       1=safety in effect 
	;  102         CYCLE_SAFETY         B       1=safety in effect 
	;  103         ANODE_SAFETY         B       1=safety in effect 
        ;  104         STRIP_SAFETY         B       1=safety in effect 
        ;  105            HV_SAFETY         B       1=safety in effect                                
        ;  106        BRIGHT_SAFETY         B       1=safety in effect 
        ;  107         UNSAFE_TIMER         I       Remaining unsafe period in seconds, 0=no safety
        ;  108      SAFETY_OVERRIDE         B       1=all safety handling is overridden (deactivate
        ;  109     TEMP_SAFETY_MASK         B       1=masked 
        ;  110    CYCLE_SAFETY_MASK         B       1=masked 
        ;  111    ANODE_SAFETY_MASK         B       1=masked 
        ;  112    STRIP_SAFETY_MASK         B       1=masked 
        ;  113       HV_SAFETY_MASK         B       1=masked 
        ;  114   BRIGHT_SAFETY_MASK         B       1=masked 
        ;  115       EXECUTING_CODE         B       0=illegal, 1=PROM, ..., 5=RAM, ..., 11-14=EEPRO
        ;  116           HW_VERSION         B       Board version ID 
        ;  117         SW_MAJOR_VER         B       Build Number 
        ;  118         SW_MINOR_VER         B       Version Number 
        ;  119           TC_INT_OFF         B       Interrupt disable for each TC receiver, 1=disab
        ;  120           SYNC_RECVD         B       TSP received in last second for each TC receive
        ;  121         TC_FRAME_ERR         B       Latched H/W frame error status for each TC rece
	;  122       TC_OVERRUN_ERR         B       Latched H/W frame error status for each TC rcvr
	;  123           MEM_CHKSUM         I       Checksum calculated in response to last issued 
        ;  124             RTX_IDLE         I       Count of passes through the scheduler idle loop
	;  125        RTX_SCHEDULER         I       Count of calls to scheduler 
        ;  126          DEBUG_ARRAY       10B       Various debug information fields 
        ;  127       MIN_FREE_STACK         B       Minimum amount of free stack space detected 
        ;  128        FIRST_DELETED         B       Task number of the first deleted task 
	;  129     RAM_EDAC_RECOVER         B       Number of recovered RAM errors 
	;  130        RAM_EDAC_FAIL         B       Number of detected RAM errors 
	;  131  EEPROM_EDAC_RECOVER         B       Number of recovered EEPROM errors 
        ;  132     EEPROM_EDAC_FAIL         B       Number of detected EEPROM errors 
        ;  133          TEST_STATUS         I       Test result of commanded self test 
        ;  134      SCRUBBER_CYCLES         I       Number of EDAC scrubber cycles completed 
        ;  135     SLOW_TASK_STATUS         B       0=start,1=idle,2=mem chk,3=mem dump,4=mem load,
	;  136   WATCHDOG_CNT_MAXED         B       Watchdog expiration count above 15 
	;  137   WATCHDOG_EXP_COUNT         B       Number of watchdog expirations since last power
        ;  138      PARAMETER_INDEX         B       Last requested parameter index 
        ;  139      PARAMETER_VALUE         B       Current value of last requested parameter 
        ;  140        HK_PKT_CHKSUM         I       Calculated checksum before sending HK data to S
        ;  141         CLOCK_PERIOD         J       Clock period assigned to HK 
	;  142         CHKSUM_ERROR         I       Difference between computed and expected packet
        ;  143         AVR_RAW_RATE   Hz    J       Average raw countrate in Hz 
        ;  144       AVR_EVENT_RATE   Hz    J       Average event rate in Hz 

   ;Extension = 11
      ;   HDR11            STRING    Array[518]
      ;   TAB11            BYTE      Array[392]
      ;>ftab_help,filename,exten_no=11
      ;Extension No: 11
      ;FITS Binary Table Header
      ;Size of Table Array: 392 by 1
      ;Extension Name:   Parameter Lists
      ; 
      ;Field                 Name    Unit Frmt Null Comment
      ; 
      ;    1            SCLK_TIME            D       Spacecraft clock (seconds since epoch) 
      ;    2             TABLE_ID            B       Ident used to distinguish redundant table copie
      ;    3         DetPwrEnable            B       Enable Detector power switch (1 = on in ACQUIRE
      ;    4           DoorEnable            B       Enable door close on safety (1 = close on safet
      ;    5          Edac2enable            B       Enable dual EDAC error restart 
      ;    6      WpaSensorEnable            B       Enable wax pellet actuator sensor feedback (1 =
      ;    7           AutoEnable            B       0 = both disabled; 1 = enable A; 2 = enable B 
      ;    8      HtrSenseGrating            B       Optics heater sensor select; 0 = primary, 1 = s
      ;    9    HtrSenseOapMirror            B       Optics heater sensor select; 0 = primary, 1 = s
      ;   10   HtrSenseScanMirror            B       Optics heater sensor select; 0 = primary, 1 = s
      ;   11    GratingHtr1Enable            B       Optics heater control enabled; 1 = enabled 
      ;   12    GratingHtr2Enable            B       Optics heater control enabled; 1 = enabled 
      ;   13  OapMirrorHtr1Enable            B       Optics heater control enabled; 1 = enabled 
      ;   14  OapMirrorHtr2Enable            B       Optics heater control enabled; 1 = enabled 
      ;   15 ScanMirrorHtr1Enable            B       Optics heater control enabled; 1 = enabled 
      ;   16 ScanmirrorHtr2Enable            B       Optics heater control enabled; 1 = enabled 
      ;   17     CRIT_CMD_TIMEOUT       s    I       Critical command timeout period in seconds (min
      ;   18         TC_MAX_ERROR            B       Number of errors allowed on any Tc channels bef
      ;   19          WPA_TIMEOUT       s    I       Wax pellet actuator timeout in seconds 
      ;   20         TINI_CONTROL       s    D       Aperture door shape metal actuators control tim
      ;   21         SCAN_CONTROL       s    D       Scan mirror shape metal actuators control time 
      ;   22         DOOR_CONTROL       s    D       Aperture door motion control time in seconds/10
      ;   23       HK_PACKET_RATE       s    I       Hk packet generation rate in cyles (0=each cycl
      ;   24         REPORT_PARAM            B       Current parameter value reported in housekeepin
      ;   25     REPORT_SUB_PARAM            B       Number of sub-sample reporting cycles for the p
      ;   26        HW_VERSION_ID            B       H/W Board Version Id included in HK Tm packet 
      ;   27          STIM_ENABLE            B       Enable Pixel STIM at start of acquisition 
      ;   28          HVPS_ENABLE            B       Enable Primary/Secondary HVPS when commanded (1
      ;   29     UP_DISCRIMINATOR            B       Upper discriminator set level (1-31) 
      ;   30     LO_DISCRIMINATOR            B       Lower discriminator set level (1-31) 
      ;   31             HV_LEVEL      kV    D       High voltage operating level 
      ;   32     HV_STEP_FRACTION            D       High voltage step fraction 
      ;   33         HV_STEP_TIME       s    I       High voltage step duration 
      ;   34        HV_SAFE_LEVEL      kV    D       Safe High voltage operating level when HV backo
      ;   35      HV_SAFE_TIMEOUT       s    I       HV backoff timeout 
      ;   36      PIXEL_LIST_HACK      ms    I       Time hack used for Pixellist acquisitions 
      ;   37          ACQ_TIMEOUT       s    J       Acquisition timeout, defines backup acquisition
      ;   38      TEST_FRAME_TIME       s    D       Duration of one test frame 
      ;   39        HSEG1_SPEC_LL            I       Hot segment 1; each hot segment specification m
      ;   40        HSEG1_SPEC_UL            I       Hot segment 1; each hot segment specification m
      ;   41     HSEG1_SPATIAL_UL            B       Hot segment 1; each hot segment specification m
      ;   42     HSEG1_SPATIAL_LL            B       Hot segment 1; each hot segment specification m
      ;   43        HSEG2_SPEC_LL            I       Hot segment 2; each hot segment specification m
      ;   44        HSEG2_SPEC_UL            I       Hot segment 2; each hot segment specification m
      ;   45     HSEG2_SPATIAL_UL            B       Hot segment 2; each hot segment specification m
      ;   46     HSEG2_SPATIAL_LL            B       Hot segment 2; each hot segment specification m
      ;   47        HSEG3_SPEC_LL            I       Hot segment 3; each hot segment specification m
      ;   48        HSEG3_SPEC_UL            I       Hot segment 3; each hot segment specification m
      ;   49     HSEG3_SPATIAL_UL            B       Hot segment 3; each hot segment specification m
      ;   50     HSEG3_SPATIAL_LL            B       Hot segment 3; each hot segment specification m
      ;   51        HSEG4_SPEC_LL            I       Hot segment 4; each hot segment specification m
      ;   52        HSEG4_SPEC_UL            I       Hot segment 4; each hot segment specification m
      ;   53     HSEG4_SPATIAL_UL            B       Hot segment 4; each hot segment specification m
      ;   54     HSEG4_SPATIAL_LL            B       Hot segment 4; each hot segment specification m
      ;   55        HSEG5_SPEC_LL            I       Hot segment 5; each hot segment specification m
      ;   56        HSEG5_SPEC_UL            I       Hot segment 5; each hot segment specification m
      ;   57     HSEG5_SPATIAL_UL            B       Hot segment 5; each hot segment specification m
      ;   58     HSEG5_SPATIAL_LL            B       Hot segment 5; each hot segment specification m
      ;   59        HSEG6_SPEC_LL            I       Hot segment 6; each hot segment specification m
      ;   60        HSEG6_SPEC_UL            I       Hot segment 6; each hot segment specification m
      ;   61     HSEG6_SPATIAL_UL            B       Hot segment 6; each hot segment specification m
      ;   62     HSEG6_SPATIAL_LL            B       Hot segment 6; each hot segment specification m
      ;   63        HSEG7_SPEC_LL            I       Hot segment 7; each hot segment specification m
      ;   64        HSEG7_SPEC_UL            I       Hot segment 7; each hot segment specification m
      ;   65     HSEG7_SPATIAL_UL            B       Hot segment 7; each hot segment specification m
      ;   66     HSEG7_SPATIAL_LL            B       Hot segment 7; each hot segment specification m
      ;   67        HSEG8_SPEC_LL            I       Hot segment 8; each hot segment specification m
      ;   68        HSEG8_SPEC_UL            I       Hot segment 8; each hot segment specification m
      ;   69     HSEG8_SPATIAL_UL            B       Hot segment 8; each hot segment specification m
      ;   70     HSEG8_SPATIAL_LL            B       Hot segment 8; each hot segment specification m
      ;   71        MAX_SPIN_TIME       s    I       Maximum spin duration in seconds (2 = pure spin
      ;   72         NADIR_OFFSET degrees    D       Mirror start offset angle: 0-2pi (0 disables Na
      ;   73         SMIB_MAX_POS            B       Maximum scan mirror position in steps 
      ;   74     SCAN_MODE_SELECT           5A       
      ;   75    ACTIVE_DUTY_CYCLE       %    B       Active Hold duty cycle (0-100%) 
      ;   76         PHASE_0_DUTY       %   4A       
      ;   77         PHASE_1_DUTY       %   4A       
      ;   78         PHASE_2_DUTY       %   4A       
      ;   79         PHASE_3_DUTY       %   4A       
      ;   80    INITIAL_QUAL_FACT            B       Initial quality number 
      ;   81        QUAL_DURATION    #/64    D       Quality duration weight factor 
      ;   82          QUAL_OPT_CR      Hz    J       Quality optimal countrate 
      ;   83       QUAL_DEVIATION   #/256    D       Quality deviation weight factor 
      ;   84         MAX_CNT_RATE     kHz    D       Maximum Countrate that triggers a countrate saf
      ;   85       CR_FAIL_BRIGHT            B       Bright Light max fail count 
      ;   86        HIGH_CNT_RATE     kHz    D       High Countrate 
      ;   87        HV_MAX_CYCLES            B       Maximum HV backoff cycles per acquisition 
      ;   88        HV_LOW_SAFETY      kV    D       HV lowest voltage setting above which the safet
      ;   89       DAC_ADC_FACTOR            D       Converstion from to DAC setting to ADC read bac
      ;   90        HV_MAX_HV_SET      kV    D       Maximum allowed HV setpoint voltage 
      ;   91           HV_MCP_TOL       V    D       MCP voltage tolerance 
      ;   92          HV_FAIL_MCP            B       MCP voltage max fail count 
      ;   93       HV_MAX_STRIP_I      uA    D       Maximum allowed strip current 
      ;   94        HV_FAIL_STRIP            B       Strip current max fail count 
      ;   95       HV_MIN_ANODE_V       V    D       Minimum allowed anode voltage 
      ;   96       HV_MAX_ANODE_V       V    D       Maximum allowed anode voltage 
      ;   97        HV_FAIL_ANODE            B       Anode voltage max fail count 
      ;   98     MAX_SCANMIR1TEMP       C    D       Maximum allowed temperature 
      ;   99     MAX_SCANMIR2TEMP       C    D       Maximum allowed temperature 
      ;  100     MAX_OAP_MIR1TEMP       C    D       Maximum allowed temperature 
      ;  101     MAX_OAP_MIR2TEMP       C    D       Maximum allowed temperature 
      ;  102     MAX_GRATING1TEMP       C    D       Maximum allowed temperature 
      ;  103     MAX_GRATING2TEMP       C    D       Maximum allowed temperature 
      ;  104         MAX_CDH_TEMP       C    D       Maximum allowed temperature 
      ;  105        MAX_HVPS_TEMP       C    D       Maximum allowed temperature                    
      ;  106        MAX_LVPS_TEMP       C    D       Maximum allowed temperature 
      ;  107       MAX_DET_B_TEMP       C    D       Maximum allowed temperature 
      ;  108       MAX_DET_E_TEMP       C    D       Maximum allowed temperature 
      ;  109        MAX_SMIB_TEMP       C    D       Maximum allowed temperature 
      ;  110     MAX_CHASSIS_TEMP       C    D       Maximum allowed temperature 
      ;  111          SAFETY_MASK            B       Initial startup value for the safety mask and o
      ;  112       SAFETY_TIMEOUT       s    I       Safety timeout 
      ;  113           DEBUG_TEST            B       Debug/Test setting 
      ;  114         WRITE_CYCLES            I       Accumulated count of changes made to the parame
