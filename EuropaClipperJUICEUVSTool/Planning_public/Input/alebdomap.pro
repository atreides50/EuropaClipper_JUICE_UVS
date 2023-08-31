PRO AlebdoMap

; Form for the reflectance function, will adapt to apply to other moons as well
; if there are minneart photometric fits for B0 and k for these moons
; 
; minneart_refl(lat, lon, emission, incidence, phase, moon)

restore, '/Users/sjarmak/AlbedoMapsWithLatLon.sav'

; Albedo Map Variable Names:
; europa_norm, europa_UV, ganymede_norm, ganymede_UV, io_norm, io_UV, callisto_norm, callisto_UV
; europa_lat, europa_lon, ganymede_lat, ganymede_lon, io_lat, io_lon, callisto_lat, callisto_lon

; Latitude and longitude value bounds
; Lat: -90 to 90
; Lon: -180 to 180

; Pick a location
lat = -60.0
lon = 30.0

; Pick some different emission and incidence angles, will need to meet the 
; criteria for phase = emission + incidence for this quick test

emission = [0.0, 20.0, 50.0, 70]
incidence = [0.0, 30.0, 40.0, 70]

colorlist = ['blue', 'green', 'red', 'purple', 'cyan']

FOR i = 0, n_elements(emission) - 1 DO BEGIN
  
       ; Find lat and lon indices closest to the user specified lat and lon
       lat_idx_diff = abs(europa_lat - lat)
       lat_idx = (where(lat_idx_diff eq min(lat_idx_diff)))[0]
       lon_idx_diff = abs(europa_lon - lon)
       lon_idx = (where(lon_idx_diff eq min(lon_idx_diff)))[0]
      
      ; MINNEART REFLECTANCE MODEL
      ; 
       alpha = emission[i] + incidence[i] ; only true if the target-observer vector, target normal vector at surface point and target-sun vector coplanar, will need more complicated relation of phase or to just use it as input 

       ; Pick which photometric equation for k to use based on
       ; comparable albedo estimate for that region
       
       ; scaling between two arbitrary values 
       ; f(min) = a
       ; f(max) = b
       ; f(x) = ((b - a)/(x - min))/(max - min) + a
       ; Scale the normalized albedo to between the min and max albedos for B0       
       MinnScaled_Albedo = ((1.726 - 0.487)*(europa_norm - MIN(europa_norm)))/(MAX(europa_norm) - MIN(europa_norm)) + 0.487
       
       
       ; Use lat and lon value to find scaled albedo val on map 
       MinnAlbedoLoc = MinnScaled_Albedo[lon_idx, lat_idx]
       
       
      ; Calculate Bs and ks from alpha value 
      ; e.g. for ridged plains, bands, high-albedo chaos, mottled chaos, low-albedo chaos, crater material, continuous crater ejecta  
       B = [-0.002*alpha + 0.728, -0.003*alpha + 0.739, -0.011*alpha + 1.726, -0.001*alpha + 0.647, 0.002*alpha + 0.487, -0.008*alpha + 1.056, -0.005*alpha + 0.940] 
       k = [0.004*alpha + 0.532, 0.003*alpha + 0.563, -0.001*alpha + 1.046, 0.004*alpha + 0.541, 0.008*alpha + 0.358, -0.007*alpha + 1.158, -0.006*alpha + 1.036]
       
      ; Find index of B0 closest to the scaled albedo for our lat, lon selection and phase angle      
       B_diff = abs(B - MinnAlbedoLoc)
       B_idx  = (where(B_diff eq min(B_diff)))[0]
       
       ; Use that index and phase angle to set the value for k
       k_loc = k[B_idx]
      
      ; Define remaining photometric model parameters
       mu0 = cos(incidence[i]*!DTOR)
       mu  = cos(emission[i]*!DTOR)
       
       ; We'll replace B0 in the Minneart model with our UV albedo value for the given lat, lon
       albedo_UV = europa_UV[lon_idx, lat_idx]
       
       refl = albedo_UV*(mu0^k_loc)*(mu^(k_loc - 1))
      
      ; Read in solar spectrum CSV file
      ; Scale spectrum by UV reflectance to get scaled irradiance as function of wavelength 
      
       solar_spec = READ_CSV('/Users/sjarmak/Downloads/solarspec.csv')
       wvl = solar_spec.FIELD2
       irrad = solar_spec.FIELD3
       
       ; Plot the test cases
       solarspec_plot_scale = plot(wvl, irrad*refl, NAME='Alpha = ' + STRING(alpha, format='(d0.2)'), color=colorlist[i], DIMENSIONS=[2000, 1600], font_size = 40, title = 'Solar Spectrum Scaled UV Reflectance', /overplot)
       solarspec_plot_scale.xtitle = 'Wavelength (nm)'
       solarspec_plot_scale.ytitle = 'Irradiance (W/m^2/nm)'
       
ENDFOR
 l = LEGEND(font_size = 20, transparency=100, pos = [0.8, 0.8])


END