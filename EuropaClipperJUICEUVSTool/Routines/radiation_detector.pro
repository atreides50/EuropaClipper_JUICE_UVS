pro radiation_detector, spacecraft, spacecraft_id, time_array_et, time_array_utc, n_pix_y, moon, w_ea, ea_AP, ea_SP, wvl, irrad, $
                        rho_dip_sc_RJ, z_dip_sc_RJ, detector_counts_radiation


n_t = n_elements(time_array_et)
n_w = n_elements(wvl)
detector_counts_radiation = dblarr(n_w, n_pix_y, n_t)

file_sav = '/Users/sjarmak/EuropaClipper/Planning/Input/lookup_table_cyl_20220729.sav'

if file_test(file_sav) eq 0 then begin
  rad_file_juno = '/Users/sjarmak/EuropaClipper/Planning/Input/lookup_table_cyl_20220729.csv'

  f = READ_CSV(rad_file_juno)
  
  rho_rad = fill_array(0.,24.,n_elements(f.field01))
  rho_rad += (rho_rad[1:-1] - rho_rad[0:-2])/2
  z_rad = fill_array(-9., 9., 71)
  
  radiation_table = [ [f.field01[1:-1]], [f.field02[1:-1]], [f.field03[1:-1]], [f.field04[1:-1]], [f.field05[1:-1]], [f.field06[1:-1]], [f.field07[1:-1]], [f.field08[1:-1]], [f.field09[1:-1]], [f.field10[1:-1]], $
                      [f.field11[1:-1]], [f.field12[1:-1]], [f.field13[1:-1]], [f.field14[1:-1]], [f.field15[1:-1]], [f.field16[1:-1]], [f.field17[1:-1]], [f.field18[1:-1]], [f.field19[1:-1]], [f.field20[1:-1]], $
                      [f.field21[1:-1]], [f.field22[1:-1]], [f.field23[1:-1]], [f.field24[1:-1]], [f.field25[1:-1]], [f.field26[1:-1]], [f.field27[1:-1]], [f.field28[1:-1]], [f.field29[1:-1]], [f.field30[1:-1]], $
                      [f.field31[1:-1]], [f.field32[1:-1]], [f.field33[1:-1]], [f.field34[1:-1]], [f.field35[1:-1]], [f.field36[1:-1]], [f.field37[1:-1]], [f.field38[1:-1]], [f.field39[1:-1]], [f.field40[1:-1]], $
                      [f.field41[1:-1]], [f.field42[1:-1]], [f.field43[1:-1]], [f.field44[1:-1]], [f.field45[1:-1]], [f.field46[1:-1]], [f.field47[1:-1]], [f.field48[1:-1]], [f.field49[1:-1]], [f.field50[1:-1]], $
                      [f.field51[1:-1]], [f.field52[1:-1]], [f.field53[1:-1]], [f.field54[1:-1]], [f.field55[1:-1]], [f.field56[1:-1]], [f.field57[1:-1]], [f.field58[1:-1]], [f.field59[1:-1]], [f.field60[1:-1]], $
                      [f.field61[1:-1]], [f.field62[1:-1]], [f.field63[1:-1]], [f.field64[1:-1]], [f.field65[1:-1]], [f.field66[1:-1]], [f.field67[1:-1]], [f.field68[1:-1]], [f.field69[1:-1]], [f.field70[1:-1]], $
                      [f.field71[1:-1]]]

  save, rho_rad, z_rad, radiation_table, notes, filename =file_sav
endif
restore, file_sav, /verbose


for i = 0,n_t - 1 do begin
  cts_per_pix  = interp2d(radiation_table, rho_rad, z_rad, rho_dip_sc_RJ[i], z_dip_sc_RJ[i])*1. / n_pix_y / n_elements(wvl)
  detector_counts_radiation[*,*,i] = detector_counts_radiation[*,*,0]*0 + cts_per_pix
  ;print , interp2d(radiation_table, rho_rad, z_rad, rho_dip_sc_RJ[i], z_dip_sc_RJ[i])
endfor

;stop

end