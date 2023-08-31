pro display_all_kernels, meta_kernel, list_kernel=list_kernel, type_kernel=type_kernel


  ;##########################################################################
  cspice_kclear
  cspice_furnsh, meta_kernel

  list_kernel = []

  cspice_ktotal, 'ALL', count
  for i = 0, count-1  do begin
    cspice_kdata, i, 'ALL', file, type, source, handle, found
    res_splitting = STRSPLIT(file, '/')
    current_kernel = strmid(file,res_splitting[-1],strlen(file))
    ;print , current_kernel
    
    if type eq 'META' then continue
    
    list_kernel = [list_kernel, strmid(file,res_splitting[-1],strlen(file))]
  endfor




  
  return
end