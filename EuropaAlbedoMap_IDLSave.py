import os
import rasterio
import geopandas
import matplotlib.pyplot as plt
import scipy
from matplotlib.patches import Patch
from matplotlib.colors import BoundaryNorm
from matplotlib import rcParams, cycler
import numpy as np
import skimage
from skimage.transform import rescale, resize, downscale_local_mean
import pandas as pd
from skimage import util

current_dir = os.getcwd()
map_filename = "Europa_Voyager_GalileoSSI_global_mosaic_500m_0to360lon.tif"
map_subdir   = "./MapImages"
map_path     = os.path.join(map_subdir, map_filename)

europa = rasterio.open(map_path)


band1_europa   = europa.read(1)   # convert to -180 to 180

# Europa
europa_shape = np.shape(band1_europa)
xshape_europa = europa_shape[1]
europa_shift = np.roll(band1_europa, int(xshape_europa/2), axis=1)
europa_norm = (europa_shift - np.min(europa_shift))/(np.max(europa_shift) - np.min(europa_shift))
europa_shift_inv = util.invert(europa_norm)
europa_UV = europa_shift_inv*0.02
from idlpy import *

IDL.europa_norm = europa_norm
IDL.europa_UV = europa_UV


# Lat lon values
europa_lat = np.linspace(-90, 90, np.shape(europa_norm)[0])
europa_lon = np.linspace(-180, 180, np.shape(europa_norm)[1])


IDL.europa_lat   = europa_lat
IDL.europa_lon   = europa_lon

spec_subdir = "Planning_public/Input"
spec_file   = "solarspec.csv"
spec_path   = os.path.join(current_dir, spec_subdir, spec_file)
solar_spec = pd.read_csv(spec_path)

wvl = solar_spec['wavelength']
irrad = solar_spec['irradiance']

print(wvl)

IDL.wvl = wvl
IDL.irrad = irrad

sav_subdir = "Planning_public/Input/Moon_AlbedoMaps"
sav_file   = "Europa_AlbedoMaps.sav"
sav_path   = os.path.join(current_dir, sav_subdir, sav_file)
IDL.save_path = sav_path
#IDL.run("SAVE, europa_norm, europa_UV, FILENAME = save_path, /COMPRESS")
IDL.run("SAVE, europa_norm, europa_UV, FILENAME = save_path, /COMPRESS")

norm_file = "EuropaNorm.txt"
UV_file   = "EuropaUVNorm.txt"
norm_path = os.path.join(current_dir, norm_file)
UV_path   = os.path.join(current_dir, UV_file)
np.savetxt(norm_path, europa_norm, delimiter=" ")
np.savetxt(UV_path, europa_UV, delimiter=" ")
# UV albedo array names: europa_norm, europa_UV,

