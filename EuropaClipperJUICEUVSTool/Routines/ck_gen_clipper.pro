pro ck_gen_clipper

;#############################################################################################################################################
cspice_furnsh, '/Users/vhue/Kernels_SPICE/Europa_Clipper/metakernels/EuropaClipper.ker' ;Loading the metakernel



  ;############################################################################################################################
  ; Generate the msopck setup file here
  filename_setup =  '/Users/vhue/Desktop/Projects/Europa_Clipper/Planning/Input/CK_creation/setup.dat'

  openw, lun, filename_setup, /get_lun

  line1 = "LSK_FILE_NAME          = '/Users/vhue/Kernels_SPICE/generic/lsk/naif0012.tls'"
  line2 = "SCLK_FILE_NAME          = '/Users/vhue/Kernels_SPICE/Europa_Clipper/sclk/europaclipper_00000.tsc'"
  line3 = "FRAMES_FILE_NAME          = '/Users/vhue/Kernels_SPICE/Europa_Clipper/fk/clipper_v16.tf'"
  
  
  printf, lun, "  \begindata"
  printf, lun, line1
  printf, lun, line2
  printf, lun, line3 
  printf, lun, "INTERNAL_FILE_NAME     = 'dummy pointing of EUROPAM_SPACECRAFT '"  
  printf, lun, "CK_TYPE                =  3"  
  ;printf, lun, "CK_SEGMENT_ID          = 'fixed attitude at the pos ", i, " '"  
  printf, lun, "INSTRUMENT_ID          = -159000"
  printf, lun, "REFERENCE_FRAME_NAME   = 'J2000'"  
  printf, lun, "ANGULAR_RATE_PRESENT   = 'MAKE UP'"  
  printf, lun, "MAXIMUM_VALID_INTERVAL =  10000000000."
  printf, lun, "INPUT_TIME_TYPE        = 'UTC'"
  printf, lun, "INPUT_DATA_TYPE        = 'EULER ANGLES'"
  printf, lun, "EULER_ANGLE_UNITS      = 'DEGREES'"
  printf, lun, "EULER_ROTATIONS_ORDER  = ( 'X', 'Y', 'Z' )"
  printf, lun, "EULER_ROTATIONS_TYPE   = 'BODY'"
  printf, lun, "DOWN_SAMPLE_TOLERANCE  = 0.0001"
  printf, lun, "INCLUDE_INTERVAL_TABLE = 'YES'"
  printf, lun, "PRODUCER_ID            = 'Vincent Hue, SwRI'" 
  printf, lun, "\begintext"
  printf, lun, " "
  printf, lun, " The program expects the angles to be fed into it as X,Y,Z order, but the rotations are done in the BODY reference meaning that the rotations are done Z then Y then X.  Note that for working with UVS the Z rotation is assumed to always be zero."

  close, lun
  FREE_LUN, lun
  ;##############################################################################################################################################



; Filename of the text file needed to compute the ck kernel
;  filename_info = path+'CK_files/ck_creation/Juno_UVS_pre_'+date_str+'_MP_'+string(Mirror_Pos, format='(i02)')+'.dat'
filename_info = '/Users/vhue/Desktop/Projects/Europa_Clipper/Planning/Input/CK_creation/ang.dat'

; Filename of the CK kernel
filename_ck = '/Users/vhue/Desktop/Projects/Europa_Clipper/Planning/Input/CK_creation/dummy.bc'
spawn, 'rm '+filename_ck

x = 0.
y = 0.
z = 270.

; Open a file which will hold the input times and x,y,z angles for the predict
; times need to come in pairs bounding time at a given position.
openw,10, filename_info
printf,10,'  2011-280T00:00:00.0 ',x,y,z
printf,10,'  2051-001T00:00:00.0 ',x,y,z
close,10


; Generate the CK file
spawn, '/Users/vhue/icy/exe/msopck  '+filename_setup+'  '+filename_info+'  '+filename_ck


stop

; Copy the newly created CK file back to the current working directory
spawn, 'mv '+filename_ck+'  '+path+'/CK_files/ck_creation/'
; Copy the newly created CK file back to the current working directory
spawn, 'mv '+filename_info+'  '+path+'/CK_files/ck_creation/'
; Copy the newly created CK file back to the current working directory
spawn, 'mv '+filename_setup+'  '+path+'/CK_files/ck_creation/'



;#############################################################################################################################################
;#############################################################################################################################################

cspice_kclear





end

