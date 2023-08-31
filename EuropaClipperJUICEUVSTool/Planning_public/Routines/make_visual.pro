pro make_visual, plotpath, label_plot, spacecraft, spacecraft_id, time_array_et, time_array_utc, moon, lat_pixel, lon_pixel, detector_counts, wvl

;Plotting
csz = 1.6
symb = 2
symb = 16

if file_test(plotpath) eq 0 then spawn, 'mkdir '+plotpath
;spawn, 'rm '+plotpath+'*'

n_pix = n_elements(lat_pixel[*,0])
n_t = n_elements(time_array_et)

; Load albedo moon
path = '/Users/sjarmak/EuropaClipper/Planning/Input/Moon_AlbedoMaps/'
CASE 1 OF
  moon eq 'Io': begin
    albedo_file = path+'Io_AlbedoMaps.sav'
    restore, albedo_file, /verbose
    Albedo_norm = IO_NORM
    Albedo_UV = IO_UV
  end
  moon eq 'Europa': begin
    albedo_file = path+'Europa_AlbedoMaps.sav'
    restore, albedo_file, /verbose
    Albedo_norm = EUROPA_NORM
    Albedo_UV = EUROPA_UV
  end
  moon eq 'Ganymede': begin
    albedo_file = path+'Ganymede_AlbedoMaps.sav'
    restore, albedo_file, /verbose
    Albedo_norm = GANYMEDE_NORM
    Albedo_UV = GANYMEDE_UV
  end
  moon eq 'Callisto': begin
    albedo_file = path+'Callisto_AlbedoMaps.sav'
    restore, albedo_file, /verbose
    Albedo_norm = CALLISTO_NORM
    Albedo_UV = CALLISTO_UV
  end
  else: stop, 'error'
endcase

nlon = n_elements(Albedo_norm[*,0])
nlat = n_elements(Albedo_norm[0,*])
lat_map = fill_array(-90.,90., nlat)
lon_map = fill_array(360.,0., nlon)
dlon = lon_map[0] - lon_map[1]
dlat = lat_map[1] - lat_map[0]
d_ang = cos(lat_map*!Dtor) * dlon * dlat

Albedo_norm = shift(reverse(Albedo_norm, 2), -nlon/2)
Albedo_UV = shift(reverse(Albedo_UV, 2), -nlon/2)





;i_lya = wvl[where(detector_counts eq max(detector_counts),/null)]
;min_flux_lya = min( (detector_counts[*,i_lya,*])[where(detector_counts[*,i_lya,*] ne 0.,/null)] )
;max_flux_lya = max(detector_counts[*,i_lya,*])
;Det_counts_array = fill_array(min_flux_lya, max_flux_lya, 255)


tot_count_w = total(detector_counts,2)
min_cts = min(tot_count_w)
max_cts = max(tot_count_w)
Det_counts_array = fill_array(min_cts, max_cts, 255)


window,0, xs=1400, ys=700
device, decomposed=1
loadct, 0

min_lat = -35.
max_lat = 35.
min_lon = 80.
max_lon = 140.

ind_lat = where(lat_map ge min_lat and lat_map le max_lat, /null)
ind_lon = where(lon_map ge min_lon and lon_map le max_lon, /null)

cgimage, Albedo_UV[ind_lon[0]:ind_lon[-1],ind_lat[0]:ind_lat[-1]], xvector=lon_map[ind_lon], yvector=lat_map[ind_lat], xr=[max(lon_map[ind_lon]), min(lon_map[ind_lon])], $
  yr=[min(lat_map[ind_lat]),max(lat_map[ind_lat])], /axes, xt='Longitude', yt='Latitude', position=[0.05, 0.07, 0.99, 0.90], charsize=csz, stretch=1
;stop
loadct, 33
TVLCT, R, G, B, /GET

print, 'TOTAL COUNT W'
print, SIZE(tot_count_w)
for i = 0, n_t-1 do begin
  for j = 0,n_pix-1, 3 do begin
 ;   if tot_count_w[j,i] eq 0. then continue
    if tot_count_w[j,i] eq 0. or lon_pixel[j,i] eq -999. then continue
    ic = value_locate(Det_counts_array, tot_count_w[j,i])
    cgoplot, lon_pixel[j,i], lat_pixel[j,i], psym=symb, symsize=0.8, color = cgColor24( [r[ic],g[ic],b[ic]])
  endfor
endfor


;window,1, xs=1200, ys=700
;device, decomposed=1
;loadct, 0
;cgplot, (time_array_et - time_array_et[0])/60, reform(total(total(detector_counts_AP[*,*,*], 1),1)), xtitle='Time since start [min]', ytitle='Total countrate across the detector (counts/s)', charsize=1.6



for it = 0, n_t-1 do begin
  ;plotpath = '/Users/vhue/Desktop/Projects/Europa_Clipper/Planning/Plots/'
  fname = plotpath+strmid(time_array_utc[it],0,4)+strmid(time_array_utc[it],5,2)+strmid(time_array_utc[it],8,2)+'T'+strmid(time_array_utc[it],11,2)+strmid(time_array_utc[it],14,2)+strmid(time_array_utc[it],17,2)+'_'+label_plot
  plotps3, fname+'.ps', /quiet
  device, decomposed=1
  loadct, 33, /silent
  
  imscl =  GmaScl(detector_counts[*,*,it], Gamma=0.3)
  cgimage, transpose(imscl),  position = [0.15, 0.5, 0.8, 0.9], xvector=wvl, yvector=findgen(n_pix), /axes, xt='Wavelength [nm]', yt='Detector Y', title='Total countrate : '+strtrim(string(total(detector_counts[*,*,it]), f='(i10)'),2)+' Hz', charsize=csz-0.6
  
  gamma_ct, gamma_val
  cgcolorbar, minrange=0., maxrange=max(detector_counts[*,*,it])/2, position=[0.95, 0.5, 0.99, 0.9], TITLE='UVS countrate [counts/s]', minor=10, /vertical, charsize=csz-0.6
  endps
  spawn, 'ps2pdf '+fname+'.ps '+fname+'.pdf'
  ;stop
  
endfor




end