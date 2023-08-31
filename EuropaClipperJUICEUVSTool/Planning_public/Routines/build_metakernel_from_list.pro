pro build_metakernel_from_list, file, meta_kernel


list_kernel = []
readcol, file, v1, format='A'
n_ker = n_elements(v1)

if file_test(meta_kernel) eq 1 then spawn, 'rm '+meta_kernel

openw, unit, meta_kernel, WIDTH = 400, /get_lun
printf, unit, "\begindata"
printf, unit, " "
printf, unit, "PATH_VALUES = ("
printf, unit, "'/Users/vhue/Kernels_SPICE'"
printf, unit, ")"
printf, unit, " "
printf, unit, "PATH_SYMBOLS = ('KERNELS')"
printf, unit, " "
printf, unit, "KERNELS_TO_LOAD = ("

for i =0,n_ker-1 do begin
  spawn, 'rm kernel_list_temp'
  kernel_name = v1[i]
  print , kernel_name
  spawn, "find /Users/vhue/Kernels_SPICE -name '"+kernel_name+"' | grep "+kernel_name +" > kernel_list_temp 2> /dev/null"

  file = !null
  readcol, 'kernel_list_temp', format='(a100)', file, count=nf_temp, SILENT=1
  spawn , "rm kernel_list_temp"

  if nf_temp eq 0 then begin
    message, 'Error, one of the kernel from the Mike file couldnt be located'
    stop
  endif
  file = strmid(file[0], strlen('/Users/vhue/Kernels_SPICE/'))
  printf, unit, "'$KERNELS/"+file[0]+"',"
  list_kernel = [list_kernel, file[0]]
endfor


spawn, 'rm kernel_list_temp'
printf, unit, ")"
close, unit
free_lun, unit



end