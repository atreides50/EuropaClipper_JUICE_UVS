pro surface_reflectance_moon_v2, spacecraft, spacecraft_id, time_array_et, time_array_utc, moon, w_ea, ea_AP, ea_SP, sr_per_pix, wvl, irrad, $
                             lat_pixel_AP, lon_pixel_AP, pixel_incidence_angle_AP, pixel_emission_angle_AP, pixel_phase_angle_AP, dist_pixel_AP, $
                             lat_pixel_SP, lon_pixel_SP, pixel_incidence_angle_SP, pixel_emission_angle_SP, pixel_phase_angle_SP, dist_pixel_SP, $
                             detector_counts_AP, detector_counts_SP

; Constants:
h = 6.62607004d-34 ; SI
lightspeed = 299792458.d ; m / s

; irrad in (J/s/m^2/nm) at Earth'
; wvl in nm
dw = mean(wvl[1:-2] - wvl[0:-2])
n_w = n_elements(irrad)
irrad = irrad / 25. ; scaled to Jupiter distance
J_to_phot = wvl * 1d-9 / (h * lightspeed) ; photons/J
irrad_phot = irrad * J_to_phot * dw ; 'Irradiance (Photons/s/m^2)'

PSF_UVS = 0.16 ; [deg]

;Plotting
csz = 1.6
symb = 2
symb = 16
;window,0, xs=1500, ys=900
;cgplot, wvl, irrad, xt='Wavelength [nm]', yt='Irradiance [W/m^2/nm]', ys=1,xs=1,/ylog, psym=10, charsize=2, position=[0.1,0.3,0.9,0.7]

n_pix = n_elements(lat_pixel_AP[*,0])
n_t = n_elements(lat_pixel_AP[0,*])
;detector_brightness_SP = dblarr(n_w, n_pix, n_t)
detector_brightness_AP = dblarr(n_w, n_pix, n_t)
detector_counts_AP = dblarr(n_w, n_pix, n_t)
;detector_flux_SP = dblarr(n_w, n_pix, n_t)
detector_brightness_SP = dblarr(n_w, n_pix, n_t)
detector_counts_SP = dblarr(n_w, n_pix, n_t)

ea_AP_pix = rebin(interpol(ea_AP, w_ea, wvl), n_w, n_pix) * 1d-4 ; [m2]
ea_SP_pix = rebin(interpol(ea_SP, w_ea, wvl), n_w, n_pix) * 1d-4 ; [m2]


; Load albedo moon
path = '/Users/vhue/Desktop/Projects/Europa_Clipper/Planning/Input/Moon_AlbedoMaps/'
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

;Albedo_norm = Albedo_norm*0. + 1
;Albedo_UV = Albedo_UV*0. + 0.02

cspice_bodvrd, moon, "RADII", 3, radii_moon
mean_rad = mean(radii_moon)

nlon = n_elements(Albedo_norm[*,0])
nlat = n_elements(Albedo_norm[0,*])
lat_map = fill_array(-90.,90., nlat)
lon_map = fill_array(360.,0., nlon)
dlon = lon_map[0] - lon_map[1]
dlat = lat_map[1] - lat_map[0]
d_ang = cos(lat_map*!Dtor) * dlon * dlat

Albedo_norm = shift(reverse(Albedo_norm, 2), -nlon/2)
Albedo_UV = shift(reverse(Albedo_UV, 2), -nlon/2)


;### Values from Dhingra et al. 2021
;### Only valid for Europa
if moon ne 'Europa' then stop, 'Error, need to update the B and K photometric values for other moons'
B_coeff = [ [-0.002, 0.728],$
            [-0.003, 0.739],$
            [-0.011, 1.726],$
            [-0.001, 0.647],$
            [0.002, 0.487],$
            [-0.008, 1.056],$
            [-0.005, 0.940]]

B_coeff_array = [[rebin(B_coeff[*,0], 2, n_pix)],$
                [rebin(B_coeff[*,1], 2, n_pix)],$
                [rebin(B_coeff[*,2], 2, n_pix)],$
                [rebin(B_coeff[*,3], 2, n_pix)],$
                [rebin(B_coeff[*,4], 2, n_pix)],$
                [rebin(B_coeff[*,5], 2, n_pix)],$
                [rebin(B_coeff[*,6], 2, n_pix)]]

k_coeff = [ [0.004, 0.532],$
            [0.003, 0.563],$
            [-0.001, 1.046],$
            [0.004, 0.541],$
            [0.008, 0.358],$
            [-0.007, 1.158],$
            [-0.006, 1.036]]

k_coeff_array = [ [rebin(k_coeff[*,0], 2, n_pix)],$
                  [rebin(k_coeff[*,1], 2, n_pix)],$
                  [rebin(k_coeff[*,2], 2, n_pix)],$
                  [rebin(k_coeff[*,3], 2, n_pix)],$
                  [rebin(k_coeff[*,4], 2, n_pix)],$
                  [rebin(k_coeff[*,5], 2, n_pix)],$
                  [rebin(k_coeff[*,6], 2, n_pix)]]

;window,1
;device, decomposed=1
;imscl=bytscl(Albedo_UV)
;cgimage, imscl, xvector=lon_map, yvector=lat_map, xrange=[max(lon_map), min(lon_map)], yr=[min(lat_map), max(lat_map)], /axes, xt='Longitude', yt='Latitude'


for it = 0,n_elements(time_array_et)-1 do begin
 
  ind_ok = where(lon_pixel_AP[0:n_pix-1, it] ne -999.,/null)
  
  ;#######  Aiglow port 
  if ind_ok ne !null then begin

    ; Number of indices to be averaged within the albedo map to match the projected UVS PSF on the planet
    ;  ratio = projected PSF / cos(lat) * r^2 * dlat * dlon
    ;  projected PSF = pi * (d * tan(PSF/2) )^2
    projected_PSF_AP  = !Dpi * (dist_pixel_AP[0:n_pix-1,it]*tan(PSF_UVS*!Dtor/2))^2. ; km^2
    ratio_psf_gridcell = projected_PSF_AP / (mean_rad^2. * cos(lat_pixel_AP[0:n_pix-1,it]*!Dtor) * dlon * dlat * !Dtor^2)
    d_cells = ceil(sqrt(ratio_psf_gridcell)/2) > 1
    
    print , 'time ', it, min(d_cells), ' cells ', mean(dist_pixel_AP[0:n_pix-1,it]*tan(PSF_UVS*!Dtor/2)), ' km'

    ilat_AP = value_locate(lat_map, lat_pixel_AP[0:n_pix-1,it])
    ilon_AP = value_locate(lon_map, lon_pixel_AP[0:n_pix-1,it])

    mean_ilon_AP = floor(mean(ilon_AP[ind_ok]))
    alb_norm_shifted_AP = shift(Albedo_norm, nlon/2 - mean_ilon_AP)
    alb_UV_shifted_AP = shift(Albedo_UV, nlon/2 - mean_ilon_AP)
    ilon_AP2 = ilon_AP + nlon/2 - mean_ilon_AP ; shifted indices

    ; only true if the target-observer vector, target normal vector at surface point and target-sun vector coplanar, will need more complicated relation of phase or to just use it as input
    alpha_AP = pixel_emission_angle_AP[0:n_pix-1,it] + pixel_incidence_angle_AP[0:n_pix-1,it]
    
    ; Pick which photometric equation for k to use based on comparable albedo estimate for that region
    ; scaling between two arbitrary values
    ; f(min) = a
    ; f(max) = b
    ; f(x) = ((b - a)/(x - min))/(max - min) + a
    ; Scale the normalized albedo to between the min and max albedos for B0
    MinnScaled_Albedo = ((1.726 - 0.487)*(alb_norm_shifted_AP - MIN(alb_norm_shifted_AP)))/(MAX(alb_norm_shifted_AP) - MIN(alb_norm_shifted_AP)) + 0.487
    
    ; Use lat and lon value to find scaled albedo val on map
    ;MinnAlbedoLoc_AP = MinnScaled_Albedo[ilon_AP2, ilat_AP]
    MinnAlbedoLoc_AP = fltarr(n_pix)
    for ipix = 0,n_pix-1 do begin
      if lat_pixel_AP[ipix,it] ne -999 then begin
        xmin = max([ilon_AP2[ipix]-d_cells[ipix],0])
        xmax = min([ilon_AP2[ipix]+d_cells[ipix],nlon-1])
        ymin = max([ilat_AP[ipix]-d_cells[ipix],0])
        ymax = min([ilat_AP[ipix]+d_cells[ipix],nlat-1])
        MinnAlbedoLoc_AP[ipix] = mean(MinnScaled_Albedo[xmin:xmax, ymin:ymax])
      endif else begin
        MinnAlbedoLoc_AP[ipix] = 0.
      endelse
    endfor

    alpha_AP_array = reform(rebin(alpha_AP[0:n_pix-1], n_pix, 7), 7*n_pix)
    B_AP = reform(alpha_AP_array * B_coeff_array[0,*] + B_coeff_array[1,*])
    k_AP = reform(alpha_AP_array * k_coeff_array[0,*] + k_coeff_array[1,*])
    
    ; Calculate Bs and ks from alpha value
    ; e.g. for ridged plains, bands, high-albedo chaos, mottled chaos, low-albedo chaos, crater material, continuous crater ejecta

    ; Find index of B0 closest to the scaled albedo for our lat, lon selection and phase angle
    B_diff_AP = abs(reform(B_AP, n_pix, 7) - rebin(MinnAlbedoLoc_AP, n_pix, 7))
    min_B = min(B_diff_AP, dimension=2, B_idx_AP)
    
    ; Use that index and phase angle to set the value for k
    k_loc_AP = k_AP[B_idx_AP]
    
    ; Define remaining photometric model parameters
    mu0_AP = cos(pixel_incidence_angle_AP[*,it] *!DTOR)
    mu_AP  = cos(pixel_emission_angle_AP[*,it]*!DTOR)
    
    ; We'll replace B0 in the Minneart model with our UV albedo value for the given lat, lon
    ;albedo_UV_AP = alb_UV_shifted_AP[ilon_AP2, ilat_AP]
    albedo_UV_AP = fltarr(n_pix)
    for ipix = 0,n_pix-1 do begin
      if lat_pixel_AP[ipix,it] ne -999 then begin
        xmin = max([ilon_AP2[ipix]-d_cells[ipix],0])
        xmax = min([ilon_AP2[ipix]+d_cells[ipix],nlon-1])
        ymin = max([ilat_AP[ipix]-d_cells[ipix],0])
        ymax = min([ilat_AP[ipix]+d_cells[ipix],nlat-1])
        albedo_UV_AP[ipix] = mean(alb_UV_shifted_AP[xmin:xmax, ymin:ymax])
      endif else begin
        albedo_UV_AP[ipix] = 0
      endelse
    endfor
    
    refl_AP = albedo_UV_AP*(mu0_AP^k_loc_AP)*(mu_AP^(k_loc_AP - 1))
    refl_AP = albedo_UV_AP
    
    ind_AP_bad = where(lat_pixel_AP[*,it] eq -999. or pixel_incidence_angle_AP[*,it] ge 90., /null, complement=ind_ok)
    if ind_AP_bad ne !null then refl_AP[ind_AP_bad] = 0.


    if ind_ok ne !null then begin

      ;irrad_SC = transpose(rebin(irrad_phot, n_w, n_pix)) * rebin(projected_PSF_AP * cos(pixel_incidence_angle_AP[*,it] *!DTOR) / dist_pixel_AP[*,it]^2, n_pix, n_w)   ; 'Irradiance at the SC position (Photons/s/m^2)'
      irrad_SC = rebin(irrad_phot, n_w, n_pix) * transpose(rebin( cos(pixel_incidence_angle_AP[*,it] *!DTOR), n_pix, n_w)) ; 'Brightness at the SC position (Photons/s/m^2/sr-1)'

      detector_brightness_AP[*,*,it] = irrad_SC * transpose(rebin(refl_AP, n_pix, n_w)) ; (Photons/s/m^2/sr)'
      detector_counts_AP[*,*,it] = detector_brightness_AP[*,*,it] * ea_AP_pix * sr_per_pix ; (Counts/s)'

    endif
  endif
  
  
  
  
  
  
  ;#################  Solar port ##################
  ind_ok = where(lon_pixel_SP[0:n_pix-1, it] ne -999.,/null)

  if ind_ok ne !null then begin
    ; Number of indices to be averaged within the albedo map to match the projected UVS PSF on the planet
    ;  ratio = projected PSF / cos(lat) * r^2 * dlat * dlon
    ;  projected PSF = pi * (d * tan(PSF/2) )^2
    
    projected_PSF_SP  = !Dpi * (dist_pixel_SP[0:n_pix-1,it]*tan(PSF_UVS*!Dtor/2))^2. ; km^2
    ratio_psf_gridcell = projected_PSF_SP / (mean_rad^2. * cos(lat_pixel_SP[0:n_pix-1,it]*!Dtor) * dlon * dlat * !Dtor^2)
    d_cells = ceil(sqrt(ratio_psf_gridcell)/2) > 1


    ilat_SP = value_locate(lat_map, lat_pixel_SP[0:n_pix-1,it])
    ilon_SP = value_locate(lon_map, lon_pixel_SP[0:n_pix-1,it])


    mean_ilon_SP = floor(mean(ilon_SP[ind_ok]))
    alb_norm_shifted_SP = shift(Albedo_norm, nlon/2 - mean_ilon_SP)
    alb_UV_shifted_SP = shift(Albedo_UV, nlon/2 - mean_ilon_SP)
    ilon_SP2 = ilon_SP + nlon/2 - mean_ilon_SP ; shifted indices
    mean_ilon_SP = floor(mean(ilon_SP[where(lon_pixel_SP[0:n_pix-1,it] ne -999.,/null)]))
    

    alpha_SP = pixel_emission_angle_SP[0:n_pix-1,it] + pixel_incidence_angle_SP[0:n_pix-1,it]
  
    ; Pick which photometric equation for k to use based on comparable albedo estimate for that region
    ; scaling between two arbitrary values
    ; f(min) = a
    ; f(max) = b
    ; f(x) = ((b - a)/(x - min))/(max - min) + a
    ; Scale the normalized albedo to between the min and max albedos for B0
    MinnScaled_Albedo = ((1.726 - 0.487)*(alb_norm_shifted_SP - MIN(alb_norm_shifted_SP)))/(MAX(alb_norm_shifted_SP) - MIN(alb_norm_shifted_SP)) + 0.487
  
  
    ; Use lat and lon value to find scaled albedo val on map
    ;MinnAlbedoLoc_SP = MinnScaled_Albedo[ilon_SP2, ilat_SP]
    MinnAlbedoLoc_SP = fltarr(n_pix)
    for ipix = 0,n_pix-1 do begin
      if lat_pixel_SP[ipix,it] ne -999 then begin
        xmin = max([ilon_SP2[ipix]-d_cells[ipix],0])
        xmax = min([ilon_SP2[ipix]+d_cells[ipix],nlon-1])
        ymin = max([ilat_SP[ipix]-d_cells[ipix],0])
        ymax = min([ilat_SP[ipix]+d_cells[ipix],nlat-1])
        MinnAlbedoLoc_SP[ipix] = mean(MinnScaled_Albedo[xmin:xmax, ymin:ymax])
      endif else begin
        MinnAlbedoLoc_SP[ipix] = 0
      endelse
    endfor

    alpha_SP_array = reform(rebin(alpha_SP[0:n_pix-1], n_pix, 7), 7*n_pix)
    B_SP = reform(alpha_SP_array * B_coeff_array[0,*] + B_coeff_array[1,*])
    k_SP = reform(alpha_SP_array * k_coeff_array[0,*] + k_coeff_array[1,*])
    
    
    ; Calculate Bs and ks from alpha value
    ; e.g. for ridged plains, bands, high-albedo chaos, mottled chaos, low-albedo chaos, crater material, continuous crater ejecta
    ; Find index of B0 closest to the scaled albedo for our lat, lon selection and phase angle
    B_diff_SP = abs(reform(B_SP, n_pix, 7) - rebin(MinnAlbedoLoc_SP, n_pix, 7))
    min_B = min(B_diff_SP, dimension=2, B_idx_SP)
    
    
    ; Use that index and phase angle to set the value for k
    k_loc_SP = k_SP[B_idx_SP]
    
    
    ; Define remaining photometric model parameters
    mu0_SP = cos(pixel_incidence_angle_SP[*,it] *!DTOR)
    mu_SP  = cos(pixel_emission_angle_SP[*,it]*!DTOR)
    
    
    ; We'll replace B0 in the Minneart model with our UV albedo value for the given lat, lon
    ;albedo_UV_SP = alb_UV_shifted_SP[ilon_SP2, ilat_SP]
    albedo_UV_SP = fltarr(n_pix)
    for ipix = 0,n_pix-1 do begin
      if lat_pixel_SP[ipix,it] ne -999 then begin
         xmin = max([ilon_SP2[ipix]-d_cells[ipix],0])
         xmax = min([ilon_SP2[ipix]+d_cells[ipix],nlon-1])
         ymin = max([ilat_SP[ipix]-d_cells[ipix],0])
         ymax = min([ilat_SP[ipix]+d_cells[ipix],nlat-1])
         ;MinnAlbedoLoc_SP[ipix] = mean(MinnScaled_Albedo[xmin:xmax, ymin:ymax])
         albedo_UV_SP[ipix] = mean(alb_UV_shifted_SP[xmin:xmax, ymin:ymax])
      endif else begin
         albedo_UV_SP[ipix] = 0.
      endelse
    endfor
    
    refl_SP = albedo_UV_SP*(mu0_SP^k_loc_SP)*(mu_SP^(k_loc_SP - 1))
    refl_SP = albedo_UV_SP
    
    ind_SP_bad = where(lat_pixel_SP[*,it] eq -999. or pixel_incidence_angle_SP[*,it] ge 90., /null, complement=ind_ok)
    if ind_SP_bad ne !null then refl_SP[ind_SP_bad] = 0.
    
    if ind_ok ne !null then begin
      ;irrad_phot_poisson =  transpose(rebin(irrad_phot, n_w, n_pix))
      ;irrad_phot_poisson = POIDEV(irrad_phot_poisson, SEED = seed)

      irrad_SC = rebin(irrad_phot, n_w, n_pix) * transpose(rebin(cos(pixel_incidence_angle_SP[*,it] *!DTOR), n_pix, n_w))  ; 'Irradiance at the SC position (Photons/s/m^2/sr)'

      detector_brightness_SP[*,*,it] = irrad_SC * transpose(rebin(refl_SP, n_pix, n_w))  ; (Photons/s/m^2/sr)'
      detector_counts_SP[*,*,it] = detector_brightness_SP[*,*,it] * ea_SP_pix * sr_per_pix ; (Counts/s)'
      
    endif
  endif
  
  
;  if it eq 15 then begin
;    imscl = GmaScl(detector_counts_AP[*,*,it], Gamma=0.3)
;    cgimage, transpose(imscl), xvector=wvl, yvector=indgen(n_pix), /axes, xt='Wavelength [nm]', yt='Detector pixel'
;  endif

  
endfor


;spawn, 'gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile='+plotpath+'AP_Merged.pdf '+plotpath+'AP_Time*.pdf'



;stop
end