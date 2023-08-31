pro load_solar_spectrum, wvl, irrad

; Load solar spectrum
solar_spec = READ_CSV('/Users/sjarmak/EuropaClipper/VincentCode/Planning_public/Input/solarspec.csv')
wvl = solar_spec.FIELD2  ; 'Wavelength (nm)'
irrad = solar_spec.FIELD3 ; 'Irradiance (J/s/m^2/nm) at Earth'


end