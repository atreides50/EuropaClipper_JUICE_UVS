pro calculate_rho_z_dipole, range_jupiter, sub_jupiter_lon, sub_jupiter_lat, rho_dip, z_dip

sub_jupiter_lon_dipole = sub_jupiter_lon
sub_jupiter_lat_dipole = sub_jupiter_lat
rotate_into_dipole, sub_jupiter_lon, sub_jupiter_lat, sub_jupiter_lon_dipole, sub_jupiter_lat_dipole, rotation_direction='forward'

; Conversion into east-longitude to input into cspice_latrec routine
sub_jupiter_lon_dipole_e = sub_jupiter_lon_dipole
convert_s3_e_lon_vec, sub_jupiter_lon_dipole_e
cspice_latrec, range_jupiter, sub_jupiter_lon_dipole_e*!Dtor, sub_jupiter_lat_dipole*!Dtor, xyz_dipole

rho_dip = reform(sqrt(xyz_dipole[0,*]^2 + xyz_dipole[1,*]^2))
z_dip = reform(xyz_dipole[2,*])

end