pro convert_s3_lon_vec, lon_ss

ind_l0 = where(lon_ss lt 0, /null, complement=ind_g0)

if ind_l0 ne !null then lon_ss[ind_l0] = -lon_ss[ind_l0]

if ind_g0 ne !null then lon_ss[ind_g0] = 360.d -lon_ss[ind_g0]


end



