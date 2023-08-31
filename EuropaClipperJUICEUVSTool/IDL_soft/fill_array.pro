


function fill_array, t0, t1, nt
  compile_opt strictarr
  t=dblarr(nt)
  t[0]=t0
  dt=(t1-t0)/(nt-1)
  for i=1L,nt-1 do t[i]=t[i-1]+dt
  return,t
end
