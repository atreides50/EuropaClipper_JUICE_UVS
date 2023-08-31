pro time_convert_sclk_to_et_ver4,meta_kernel_file,pm,analog=analog

t=systime(1)

;tic    ;track the time it takes to run

;time to run on efb cal dataset with fast=true   93.629 secs
;time to run on slow   102.08 secs (fast improved things by (102.08-93.629)/102.08=8%

;This code is built to convert the SCLK clock times reported by LIMA from Juno UVS into Ephemeris Time (ET) 
;ET time is seconds since 2000/1/1 12:00:00.00

cspice_kclear
cspice_furnsh,meta_kernel_file


;convert the sc_rcvd_time
reported_sclk=string(pm.sc_rcvd_time,format='(i9)')+'.'+string((pm.sc_rcvd_time mod floor(pm.sc_rcvd_time))*65536,format='(i5)')

;-61 is the low precision clock at 256 per cycle and -61999 is the high precision clock at 1/65536 precision
cspice_scs2e,-61999,reported_sclk,real_et

pm.sc_rcvd_time=real_et

;convert the sc_time_first_hack
reported_sclk=string(pm.sc_time_first_hack,format='(i9)')+'.'+string((pm.sc_time_first_hack mod floor(pm.sc_time_first_hack))*65536,format='(i5)')

;-61 is the low precision clock at 256 per cycle and -61999 is the high precision clock at 1/65536 precision
cspice_scs2e,-61999,reported_sclk,real_et

pm.sc_time_first_hack=real_et

;convert the sc_time_last_hack
reported_sclk=string(pm.sc_time_last_hack,format='(i9)')+'.'+string((pm.sc_time_last_hack mod floor(pm.sc_time_last_hack))*65536,format='(i5)')

;-61 is the low precision clock at 256 per cycle and -61999 is the high precision clock at 1/65536 precision
cspice_scs2e,-61999,reported_sclk,real_et

pm.sc_time_last_hack=real_et

;convert the recv_time
reported_sclk=string(pm.recv_time,format='(i9)')+'.'+string((pm.recv_time mod floor(pm.recv_time))*65536,format='(i5)')

;-61 is the low precision clock at 256 per cycle and -61999 is the high precision clock at 1/65536 precision
cspice_scs2e,-61999,reported_sclk,real_et

pm.recv_time=real_et

reported_sclk=string(pm.position_time,format='(i9)')+'.'+string((pm.position_time mod floor(pm.position_time))*65536,format='(i5)')

;-61 is the low precision clock at 256 per cycle and -61999 is the high precision clock at 1/65536 precision
cspice_scs2e,-61999,reported_sclk,real_et

pm.position_time=real_et

;reported_sclk=string(pm.dig_scut_time,format='(i9)')+'.'
;test=(pm.dig_scut_time mod floor(pm.dig_scut_time))*65536
;reported_sclk+=string(test,format='(i5)')
s=size(pm.dig_scut_time,/dim)
test=floor(s[0]/10000000)
if (test eq 0) then begin
   reported_sclk=string(pm.dig_scut_time,format='(i9)')+'.'+string((pm.dig_scut_time mod floor(pm.dig_scut_time))*65536,format='(i5)')
   ;-61 is the low precision clock at 256 per cycle and -61999 is the high precision clock at 1/65536 precision
   cspice_scs2e,-61999,reported_sclk,real_et
   pm.dig_scut_time=real_et
endif else begin
  for i=0,test-1 do begin
     reported_sclk=string(pm.dig_scut_time[i*10000000:(i+1)*10000000-1],format='(i9)')+'.'+string((pm.dig_scut_time[i*10000000:(i+1)*10000000-1] mod floor(pm.dig_scut_time[i*10000000:(i+1)*10000000-1]))*65536,format='(i5)')
     ;-61 is the low precision clock at 256 per cycle and -61999 is the high precision clock at 1/65536 precision
     cspice_scs2e,-61999,reported_sclk,real_et
     pm.dig_scut_time[i*10000000:(i+1)*10000000-1]=real_et   ;this is the slow way to do this
;     pm.dig_scut_time[i*10000000]=real_et    ;this is the fast way to get the same result
  endfor
  reported_sclk=string(pm.dig_scut_time[(test)*10000000:*],format='(i9)')+'.'+string((pm.dig_scut_time[test*10000000:*] mod floor(pm.dig_scut_time[test*10000000:*]))*65536,format='(i5)')
  ;-61 is the low precision clock at 256 per cycle and -61999 is the high precision clock at 1/65536 precision
  cspice_scs2e,-61999,reported_sclk,real_et
  pm.dig_scut_time[test*10000000:*]=real_et  ;This is the slow way to do this
;  pm.dig_scut_time[test*10000000]=real_et   ;this is the fast way to get the same result, this doesn't work since real_et isn't structure
endelse

reported_sclk=string(pm.hk_sclk_time,format='(i9)')+'.'+string((pm.hk_sclk_time mod floor(pm.hk_sclk_time))*65536,format='(i5)')

;-61 is the low precision clock at 256 per cycle and -61999 is the high precision clock at 1/65536 precision
cspice_scs2e,-61999,reported_sclk,real_et

pm.hk_sclk_time=real_et

reported_sclk=string(pm.hk_sclk_time_ext_11,format='(i9)')+'.'+string((pm.hk_sclk_time_ext_11 mod floor(pm.hk_sclk_time_ext_11))*65536,format='(i5)')

;-61 is the low precision clock at 256 per cycle and -61999 is the high precision clock at 1/65536 precision
cspice_scs2e,-61999,reported_sclk,real_et

pm.hk_sclk_time_ext_11=real_et

if keyword_set(analog) then begin
;included analog rate so convert ana_scut_time
reported_sclk=string(pm.ana_scut_time,format='(i9)')+'.'+string((pm.ana_scut_time mod floor(pm.ana_scut_time))*65536,format='(i5)')
;-61 is the low precision clock at 256 per cycle and -61999 is the high precision clock at 1/65536 precision
cspice_scs2e,-61999,reported_sclk,real_et
pm.ana_scut_time=real_et
endif


cspice_kclear

print,'time to run code was = ',systime(1)-t
;print,'time to run code was = ',toc

return
end

