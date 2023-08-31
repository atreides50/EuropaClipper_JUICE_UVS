pro compute_geometry_element, path_geometry, time_array_et, time_array_utc, spacecraft, filename_geometry
; Input: array of times in ephemeris time 
;
; Output: IDL sav file "filename_geometry" containing the ephemeris outputs
; Author: Vincent Hue (SwRI, 2022)


; Initialization of the variables
init_variable, sc_range_jupiter, sc_range_jupiter_RJ, subsc_jupiter_lat, subsc_jupiter_lon, mag_lat_sc, cent_lat_sc,$
               subsolar_jupiter_lon , subsolar_jupiter_lat , subearth_jupiter_lon , subearth_jupiter_lat,$
               size_jupiter , size_Io , size_europa , size_ganymede , size_callisto,$
               subsc_io_lat , subsc_io_lon , subio_jupiter_lat , subio_jupiter_lon , subsolar_io_lat , subsolar_io_lon , range_sc_io , altitude_sc_io , local_time_Io , eclipse_io , mag_lat_io , cent_lat_io,$
               subsc_europa_lat , subsc_europa_lon , subeuropa_jupiter_lat , subeuropa_jupiter_lon , subsolar_europa_lat , subsolar_europa_lon , range_sc_europa , altitude_sc_europa , local_time_Europa , eclipse_europa , mag_lat_europa , cent_lat_europa,$
               subsc_ganymede_lat , subsc_ganymede_lon , subganymede_jupiter_lat , subganymede_jupiter_lon , subsolar_ganymede_lat , subsolar_ganymede_lon , range_sc_ganymede , altitude_sc_ganymede , local_time_Ganymede , eclipse_ganymede , mag_lat_ganymede , cent_lat_ganymede,$
               subsc_callisto_lat , subsc_callisto_lon , subcallisto_jupiter_lat , subcallisto_jupiter_lon , subsolar_callisto_lat , subsolar_callisto_lon , range_sc_callisto , altitude_sc_callisto , local_time_Callisto , eclipse_callisto , mag_lat_callisto , cent_lat_callisto,$
               RA_AP , DEC_AP , RA_SP , DEC_SP , rate_boresight_sky_AP , rate_boresight_sky_SP , $
               lat_boresight_AP_jupiter , lon_boresight_AP_jupiter , lat_boresight_SP_jupiter , lon_boresight_SP_jupiter , rate_boresight_jupiter_AP , rate_boresight_jupiter_SP, Jupiter_AP_angle , Jupiter_SP_angle , $
               lat_boresight_AP_io , lon_boresight_AP_io , lat_boresight_SP_io , lon_boresight_SP_io , rate_boresight_io_AP , rate_boresight_io_SP, Io_AP_angle , Io_SP_angle , $
               lat_boresight_AP_europa , lon_boresight_AP_europa , lat_boresight_SP_europa , lon_boresight_SP_europa , rate_boresight_europa_AP , rate_boresight_europa_SP , Europa_AP_angle , Europa_SP_angle , $
               lat_boresight_AP_ganymede , lon_boresight_AP_ganymede , lat_boresight_SP_ganymede , lon_boresight_SP_ganymede , rate_boresight_ganymede_AP , rate_boresight_ganymede_SP , Ganymede_AP_angle , Ganymede_SP_angle , $
               lat_boresight_AP_Callisto , lon_boresight_AP_Callisto , lat_boresight_SP_Callisto , lon_boresight_SP_Callisto , rate_boresight_callisto_AP , rate_boresight_callisto_SP , Callisto_AP_angle , Callisto_SP_angle ,$
               lat_pixel_AP_io , lon_pixel_AP_io , pixel_incidence_angle_AP_io , pixel_emission_angle_AP_io , pixel_phase_angle_AP_io , dist_pixel_AP_io , $
               lat_pixel_SP_io , lon_pixel_SP_io , pixel_incidence_angle_SP_io , pixel_emission_angle_SP_io , pixel_phase_angle_SP_io , dist_pixel_SP_io ,$
               lat_pixel_AP_europa , lon_pixel_AP_europa , pixel_incidence_angle_AP_europa , pixel_emission_angle_AP_europa , pixel_phase_angle_AP_europa , dist_pixel_AP_europa,$
               lat_pixel_SP_europa , lon_pixel_SP_europa , pixel_incidence_angle_SP_europa , pixel_emission_angle_SP_europa , pixel_phase_angle_SP_europa , dist_pixel_SP_europa,$
               lat_pixel_AP_ganymede , lon_pixel_AP_ganymede , pixel_incidence_angle_AP_ganymede , pixel_emission_angle_AP_ganymede , pixel_phase_angle_AP_ganymede , dist_pixel_AP_ganymede ,$
               lat_pixel_SP_ganymede , lon_pixel_SP_ganymede , pixel_incidence_angle_SP_ganymede , pixel_emission_angle_SP_ganymede , pixel_phase_angle_SP_ganymede , dist_pixel_SP_ganymede ,$
               lat_pixel_AP_callisto , lon_pixel_AP_callisto , pixel_incidence_angle_AP_callisto , pixel_emission_angle_AP_callisto , pixel_phase_angle_AP_callisto , dist_pixel_AP_callisto ,$
               lat_pixel_SP_callisto , lon_pixel_SP_callisto , pixel_incidence_angle_SP_callisto , pixel_emission_angle_SP_callisto , pixel_phase_angle_SP_callisto , dist_pixel_SP_callisto ,$
               eclipse_SC


 time_array_hr_since_start = (time_array_et - time_array_et[0])/3600.

 nt = n_elements(time_array_et)
 nx = 2.^12
 n_pix_y = 1009 ; Per Rohini's email on June 13 2022
 
 Earth_id='399' ;Earth
 Jupiter_id='599' ;Jupiter
 Io_id='501' ;Io
 Europa_id='502' ;Europa
 Ganymede_id='503' ;Ganymede
 Callisto_id='504' ;Callisto

 CASE 1 OF
   spacecraft eq 'Europa': begin
     spacecraft_id = '-159'
     file_eff_area = '/Users/sjarmak/Europa_Clipper/Effective_area/Ouput/Europa_UVS_EffArea_20220331.sav'
     file_wavelength_solution = '/Users/sjarmak/Europa_Clipper/Effective_area/Wavelength_solution/wavelength_solution_europa.sav'
     sr_per_pix =  0.0075 * 0.1 * (!Dpi/180)^2 ; pixels are 0.1˚ x 0.0075˚ (per M Davis Europa-UVS ENGINEERING MEMORANDUM)
   end
   spacecraft eq 'JUICE': begin
     spacecraft_id = '-28'
     file_eff_area = '/Users/vhue/Desktop/Projects/Europa_Clipper/Effective_area/Ouput/JUICE_UVS_EffArea_20220331.sav'
     file_wavelength_solution = '/Users/vhue/Desktop/Projects/JUICE/Effective_area/Wavelength_solution/wavelength_solution_juice.sav'
     sr_per_pix = -999. ; TODO
   end
 end


 ; Get Jupiter's radii from the kernel pool
 cspice_bodvrd, 'JUPITER', "RADII", 3, radii_jup
 cspice_bodvrd, 'Io', "RADII", 3, radii_io
 cspice_bodvrd, 'Europa', "RADII", 3, radii_eur
 cspice_bodvrd, 'Ganymede', "RADII", 3, radii_gan
 cspice_bodvrd, 'Callisto', "RADII", 3, radii_cal

 cspice_spkezr, spacecraft_id, time_array_et, 'IAU_JUPITER', 'CN+S', Jupiter_id, sc_state, ltime
 sc_range_jupiter = reform(sqrt(sc_state[0,*]^2 + sc_state[1,*]^2 + sc_state[2,*]^2))
 sc_range_jupiter_RJ = sc_range_jupiter/radii_jup[0]

 ; Sub-SC jovian lat/lon
 cspice_reclat, sc_state[0:2,*], radius, subsc_jupiter_lon, subsc_jupiter_lat
 
 subsc_jupiter_lat=subsc_jupiter_lat/!dtor
 subsc_jupiter_lon=subsc_jupiter_lon/!dtor
 convert_s3_lon_vec, subsc_jupiter_lon

 calculate_mag_cent_latitudes_from_s3wlon, subsc_jupiter_lon, subsc_jupiter_lat, mag_lat_sc, cent_lat_sc
 calculate_rho_z_dipole, sc_range_jupiter, subsc_jupiter_lon, subsc_jupiter_lat, rho_dip_sc, z_dip_sc
 rho_dip_sc_RJ = rho_dip_sc/radii_jup[0]
 z_dip_sc_RJ = z_dip_sc/radii_jup[0]

 
; cspice_furnsh, '/Users/vhue/Kernels_SPICE/Juno/metakernels/Meta_kernel_all.ker'
; t_juno = '2022-08-17 14:45:33'
; cspice_str2et, t_juno, t_juno_et
; t_juno_et = fill_array(t_juno_et - 15.*3600.*24, t_juno_et + 15.*3600.*24, 10000)
; cspice_spkezr, 'JUNO', t_juno_et, 'IAU_JUPITER', 'CN+S', Jupiter_id, sc_state, ltime
; sc_range_jupiter = reform(sqrt(sc_state[0,*]^2 + sc_state[1,*]^2 + sc_state[2,*]^2))
; cspice_reclat, sc_state[0:2,*], radius, subsc_jupiter_lon, subsc_jupiter_lat
; subsc_jupiter_lat=subsc_jupiter_lat/!dtor
; subsc_jupiter_lon=subsc_jupiter_lon/!dtor
; convert_s3_lon_vec, subsc_jupiter_lon
; calculate_rho_z_dipole, sc_range_jupiter, subsc_jupiter_lon, subsc_jupiter_lat, rho_dip_sc, z_dip_sc

 


; Sub-solar jovian lat/lon
cspice_spkezr, 'Sun', time_array_et, 'IAU_JUPITER', 'CN+S', Jupiter_id, sun_state, ltime
cspice_reclat, sun_state[0:2,*], radius, subsolar_jupiter_lon, subsolar_jupiter_lat
subsolar_jupiter_lat=subsolar_jupiter_lat/!dtor
subsolar_jupiter_lon=subsolar_jupiter_lon/!dtor
convert_s3_lon_vec, subsolar_jupiter_lon

; Sub-earth jovian lat/lon
cspice_spkezr, 'Earth', time_array_et, 'IAU_JUPITER', 'CN+S', Jupiter_id, earth_state, ltime
cspice_reclat, earth_state[0:2,*], radius, subearth_jupiter_lon, subearth_jupiter_lat
subearth_jupiter_lat=subearth_jupiter_lat/!dtor
subearth_jupiter_lon=subearth_jupiter_lon/!dtor
convert_s3_lon_vec, subearth_jupiter_lon

; Calcule the size of different relevant bodies (Jupiter & moons), as seen by the SC
compute_ang_size, spacecraft_id, time_array_et, size_jupiter, 'JUPITER'
compute_ang_size, spacecraft_id, time_array_et, size_Io, 'IO'
compute_ang_size, spacecraft_id, time_array_et, size_europa, 'EUROPA'
compute_ang_size, spacecraft_id, time_array_et, size_ganymede, 'GANYMEDE'
compute_ang_size, spacecraft_id, time_array_et, size_callisto, 'CALLISTO'


calculate_subpoint_jupiter_moons, spacecraft, spacecraft_id, 'Io', time_array_et, subsc_io_lat, subsc_io_lon, subio_jupiter_lat, subio_jupiter_lon, $
                                  subsolar_io_lat, subsolar_io_lon, range_sc_io, altitude_sc_io, local_time_Io, eclipse_io,$
                                  mag_lat_io, cent_lat_io
                                  
calculate_subpoint_jupiter_moons, spacecraft, spacecraft_id, 'Europa', time_array_et, subsc_europa_lat, subsc_europa_lon, subeuropa_jupiter_lat, subeuropa_jupiter_lon,$
                                  subsolar_europa_lat, subsolar_europa_lon, range_sc_europa, altitude_sc_europa, local_time_Europa, eclipse_europa,$
                                  mag_lat_europa, cent_lat_europa
                                 
calculate_subpoint_jupiter_moons, spacecraft, spacecraft_id, 'Ganymede', time_array_et, subsc_ganymede_lat, subsc_ganymede_lon, subganymede_jupiter_lat, subganymede_jupiter_lon, $
                                  subsolar_ganymede_lat, subsolar_ganymede_lon, range_sc_ganymede, altitude_sc_ganymede, local_time_Ganymede, eclipse_ganymede,$
                                  mag_lat_ganymede, cent_lat_ganymede
                                  
calculate_subpoint_jupiter_moons, spacecraft, spacecraft_id, 'Callisto', time_array_et, subsc_callisto_lat, subsc_callisto_lon, subcallisto_jupiter_lat, subcallisto_jupiter_lon, $
                                  subsolar_callisto_lat, subsolar_callisto_lon, range_sc_callisto, altitude_sc_callisto, local_time_Callisto, eclipse_callisto,$
                                  mag_lat_callisto, cent_lat_callisto

   
calculate_FOV_sky, spacecraft, spacecraft_id, time_array_et, RA_AP, DEC_AP, RA_SP, DEC_SP, rate_boresight_sky_AP, rate_boresight_sky_SP


calculate_FOV_object, spacecraft, spacecraft_id, time_array_et, 'Jupiter',lat_boresight_AP_jupiter, lon_boresight_AP_jupiter, lat_boresight_SP_jupiter, lon_boresight_SP_jupiter,$
                      rate_boresight_jupiter_AP, rate_boresight_jupiter_SP, Jupiter_AP_angle, Jupiter_SP_angle

calculate_FOV_object, spacecraft, spacecraft_id, time_array_et, 'Io', lat_boresight_AP_io, lon_boresight_AP_io, lat_boresight_SP_io, lon_boresight_SP_io,$
                      rate_boresight_io_AP, rate_boresight_io_SP, Io_AP_angle, Io_SP_angle

calculate_FOV_object, spacecraft, spacecraft_id, time_array_et, 'Europa', lat_boresight_AP_europa, lon_boresight_AP_europa, lat_boresight_SP_europa, lon_boresight_SP_europa,$
                      rate_boresight_europa_AP, rate_boresight_europa_SP, Europa_AP_angle, Europa_SP_angle

calculate_FOV_object, spacecraft, spacecraft_id, time_array_et, 'Ganymede', lat_boresight_AP_ganymede, lon_boresight_AP_ganymede, lat_boresight_SP_ganymede, lon_boresight_SP_ganymede,$
                      rate_boresight_ganymede_AP, rate_boresight_ganymede_SP, Ganymede_AP_angle, Ganymede_SP_angle

calculate_FOV_object, spacecraft, spacecraft_id, time_array_et, 'Callisto', lat_boresight_AP_Callisto, lon_boresight_AP_Callisto, lat_boresight_SP_Callisto, lon_boresight_SP_Callisto,$
                      rate_boresight_callisto_AP, rate_boresight_callisto_SP, Callisto_AP_angle, Callisto_SP_angle


if max(size_io) gt 5 then begin
  calculate_pixel_object, spacecraft, spacecraft_id, time_array_et, n_pix_y, 'Io', lat_boresight_AP_io, lon_boresight_AP_io, lat_boresight_SP_io, lon_boresight_SP_io,$
                        rate_boresight_io_AP, rate_boresight_io_SP, io_AP_angle, io_SP_angle, $
                        lat_pixel_AP_io, lon_pixel_AP_io, pixel_incidence_angle_AP_io, pixel_emission_angle_AP_io, pixel_phase_angle_AP_io, dist_pixel_AP_io, $
                        lat_pixel_SP_io, lon_pixel_SP_io, pixel_incidence_angle_SP_io, pixel_emission_angle_SP_io, pixel_phase_angle_SP_io, dist_pixel_SP_io
endif

if max(size_europa) gt 5 then begin
  calculate_pixel_object, spacecraft, spacecraft_id, time_array_et, n_pix_y, 'Europa', lat_boresight_AP_europa, lon_boresight_AP_europa, lat_boresight_SP_europa, lon_boresight_SP_europa,$
                        rate_boresight_europa_AP, rate_boresight_europa_SP, europa_AP_angle, europa_SP_angle, $
                        lat_pixel_AP_europa, lon_pixel_AP_europa, pixel_incidence_angle_AP_europa, pixel_emission_angle_AP_europa, pixel_phase_angle_AP_europa, dist_pixel_AP_europa, $
                        lat_pixel_SP_europa, lon_pixel_SP_europa, pixel_incidence_angle_SP_europa, pixel_emission_angle_SP_europa, pixel_phase_angle_SP_europa, dist_pixel_SP_europa
endif

if max(size_ganymede) gt 5 then begin
  calculate_pixel_object, spacecraft, spacecraft_id, time_array_et, n_pix_y, 'Ganymede', lat_boresight_AP_ganymede, lon_boresight_AP_ganymede, lat_boresight_SP_ganymede, lon_boresight_SP_ganymede,$
                        rate_boresight_ganymede_AP, rate_boresight_ganymede_SP, ganymede_AP_angle, ganymede_SP_angle, $
                        lat_pixel_AP_ganymede, lon_pixel_AP_ganymede, pixel_incidence_angle_AP_ganymede, pixel_emission_angle_AP_ganymede, pixel_phase_angle_AP_ganymede, dist_pixel_AP_ganymede, $
                        lat_pixel_SP_ganymede, lon_pixel_SP_ganymede, pixel_incidence_angle_SP_ganymede, pixel_emission_angle_SP_ganymede, pixel_phase_angle_SP_ganymede, dist_pixel_SP_ganymede
endif

if max(size_callisto) gt 5 then begin
  calculate_pixel_object, spacecraft, spacecraft_id, time_array_et, n_pix_y, 'Callisto', lat_boresight_AP_callisto, lon_boresight_AP_callisto, lat_boresight_SP_callisto, lon_boresight_SP_callisto,$
                        rate_boresight_callisto_AP, rate_boresight_callisto_SP, callisto_AP_angle, callisto_SP_angle, $
                        lat_pixel_AP_callisto, lon_pixel_AP_callisto, pixel_incidence_angle_AP_callisto, pixel_emission_angle_AP_callisto, pixel_phase_angle_AP_callisto, dist_pixel_AP_callisto, $
                        lat_pixel_SP_callisto, lon_pixel_SP_callisto, pixel_incidence_angle_SP_callisto, pixel_emission_angle_SP_callisto, pixel_phase_angle_SP_callisto, dist_pixel_SP_callisto
endif


calculate_solar_eclipse_jupiter, spacecraft, time_array_et, eclipse_SC


save, filename=filename_geometry, $
      time_array_et, time_array_utc, n_pix_y, time_array_hr_since_start, spacecraft, spacecraft_id ,file_eff_area , file_wavelength_solution, sr_per_pix, radii_jup , radii_io , radii_eur , radii_gan , radii_cal , $
      sc_range_jupiter, sc_range_jupiter_RJ, subsc_jupiter_lat, subsc_jupiter_lon, mag_lat_sc, cent_lat_sc, rho_dip_sc, rho_dip_sc_RJ, z_dip_sc, z_dip_sc_RJ, $
      subsolar_jupiter_lon , subsolar_jupiter_lat , subearth_jupiter_lon , subearth_jupiter_lat,$
      size_jupiter , size_Io , size_europa , size_ganymede , size_callisto,$
      subsc_io_lat , subsc_io_lon , subio_jupiter_lat , subio_jupiter_lon , subsolar_io_lat , subsolar_io_lon , range_sc_io , altitude_sc_io , local_time_Io , eclipse_io , mag_lat_io , cent_lat_io,$
      subsc_europa_lat , subsc_europa_lon , subeuropa_jupiter_lat , subeuropa_jupiter_lon , subsolar_europa_lat , subsolar_europa_lon , range_sc_europa , altitude_sc_europa , local_time_Europa , eclipse_europa , mag_lat_europa , cent_lat_europa,$
      subsc_ganymede_lat , subsc_ganymede_lon , subganymede_jupiter_lat , subganymede_jupiter_lon , subsolar_ganymede_lat , subsolar_ganymede_lon , range_sc_ganymede , altitude_sc_ganymede , local_time_Ganymede , eclipse_ganymede , mag_lat_ganymede , cent_lat_ganymede,$
      subsc_callisto_lat , subsc_callisto_lon , subcallisto_jupiter_lat , subcallisto_jupiter_lon , subsolar_callisto_lat , subsolar_callisto_lon , range_sc_callisto , altitude_sc_callisto , local_time_Callisto , eclipse_callisto , mag_lat_callisto , cent_lat_callisto,$
      RA_AP , DEC_AP , RA_SP , DEC_SP , rate_boresight_sky_AP , rate_boresight_sky_SP , $
      lat_boresight_AP_jupiter , lon_boresight_AP_jupiter , lat_boresight_SP_jupiter , lon_boresight_SP_jupiter , rate_boresight_jupiter_AP , rate_boresight_jupiter_SP, Jupiter_AP_angle , Jupiter_SP_angle , $
      lat_boresight_AP_io , lon_boresight_AP_io , lat_boresight_SP_io , lon_boresight_SP_io , rate_boresight_io_AP , rate_boresight_io_SP, Io_AP_angle , Io_SP_angle , $
      lat_boresight_AP_europa , lon_boresight_AP_europa , lat_boresight_SP_europa , lon_boresight_SP_europa , rate_boresight_europa_AP , rate_boresight_europa_SP , Europa_AP_angle , Europa_SP_angle , $
      lat_boresight_AP_ganymede , lon_boresight_AP_ganymede , lat_boresight_SP_ganymede , lon_boresight_SP_ganymede , rate_boresight_ganymede_AP , rate_boresight_ganymede_SP , Ganymede_AP_angle , Ganymede_SP_angle , $
      lat_boresight_AP_Callisto , lon_boresight_AP_Callisto , lat_boresight_SP_Callisto , lon_boresight_SP_Callisto , rate_boresight_callisto_AP , rate_boresight_callisto_SP , Callisto_AP_angle , Callisto_SP_angle ,$
      lat_pixel_AP_io , lon_pixel_AP_io , pixel_incidence_angle_AP_io , pixel_emission_angle_AP_io , pixel_phase_angle_AP_io , dist_pixel_AP_io , $
      lat_pixel_SP_io , lon_pixel_SP_io , pixel_incidence_angle_SP_io , pixel_emission_angle_SP_io , pixel_phase_angle_SP_io , dist_pixel_SP_io ,$
      lat_pixel_AP_europa , lon_pixel_AP_europa , pixel_incidence_angle_AP_europa , pixel_emission_angle_AP_europa , pixel_phase_angle_AP_europa , dist_pixel_AP_europa,$
      lat_pixel_SP_europa , lon_pixel_SP_europa , pixel_incidence_angle_SP_europa , pixel_emission_angle_SP_europa , pixel_phase_angle_SP_europa , dist_pixel_SP_europa,$
      lat_pixel_AP_ganymede , lon_pixel_AP_ganymede , pixel_incidence_angle_AP_ganymede , pixel_emission_angle_AP_ganymede , pixel_phase_angle_AP_ganymede , dist_pixel_AP_ganymede ,$
      lat_pixel_SP_ganymede , lon_pixel_SP_ganymede , pixel_incidence_angle_SP_ganymede , pixel_emission_angle_SP_ganymede , pixel_phase_angle_SP_ganymede , dist_pixel_SP_ganymede ,$
      lat_pixel_AP_callisto , lon_pixel_AP_callisto , pixel_incidence_angle_AP_callisto , pixel_emission_angle_AP_callisto , pixel_phase_angle_AP_callisto , dist_pixel_AP_callisto ,$
      lat_pixel_SP_callisto , lon_pixel_SP_callisto , pixel_incidence_angle_SP_callisto , pixel_emission_angle_SP_callisto , pixel_phase_angle_SP_callisto , dist_pixel_SP_callisto, /compress
               
          
end