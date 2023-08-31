pro calculate_mag_cent_latitudes_from_s3wlon, s3_w_lon, jovigraphic_lat, mag_lat, cent_lat
; Calculate the following relevant information given a range of system 3 w lon and the a range of jovigraphic latitude:
; 
; Magnetic latitude
; Centrifugal latitude
;
; Vincent Hue, SwRI, 2022

dipole_tilt = 10.31 ; tilt of the JRM09 dipole
lon_tilt = 196.61 ; S3 W-longitude towards which the dipole is tilted
mag_lat = dipole_tilt * sin( (s3_w_lon - (196.61 - 90.) )* !dtor) 
mag_lat += jovigraphic_lat


; Formula of the centrifugal equator from Phipps and Bagenal 2021
; They give the jovigraphic latitude of the centrifugal equator
; In order to get the centrifugal latitude, one has to take the opposite of their equation
; and add the jovigraphic latitude of the considered body
a_phipps = 1.66
b_phipps = 0.131
c_phipps = 1.62
d_phipps = 7.76
e_phipps = 249.
e_phipps = 69.
R_gan = 14.97

s3_e_lon = 360. - s3_w_lon
cent_lat = (a_phipps * tanh( b_phipps * R_gan - c_phipps) + d_phipps) * sin( (s3_e_lon - e_phipps)*!Dtor)
cent_lat += jovigraphic_lat

end