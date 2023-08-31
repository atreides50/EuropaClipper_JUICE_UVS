;$Author: kovalick $
;$Date: 2006/03/30 20:05:12 $
;$Header: /home/cdaweb/dev/control/RCS/compile_inventory.pro,v 1.4 2006/03/30 20:05:12 kovalick Exp johnson $
;$Locker: johnson $
;$Revision: 1.4 $
;
;Copyright 1996-2013 United States Government as represented by the 
;Administrator of the National Aeronautics and Space Administration. 
;All Rights Reserved.
;
;------------------------------------------------------------------
;
;Database utility routines:
.run decode_CDFEPOCH
.run encode_CDFEPOCH
.run DeviceOpen.pro
.run DeviceClose.pro
.run TNAXES.pro
.run timeaxis_text.pro
.run bar_chart.pro
;Compile the cdf read routines
.run break_mySTRING.pro
.run print_inv_stats.pro
.run get_datasets.pro
.run inventory
