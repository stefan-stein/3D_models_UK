
# Tower Bridge ------------------------------------------------------------

# Get the data from here:
# https://data.gov.uk/dataset/5f6f7d5b-3f4c-4476-bfb8-cda490c9cf0e/lidar-composite-dtm-50cm
# You will have to download tiles TQ37nw and TQ38sw

library(tidyverse)
library(rayshader)
library(raster)

# Assuming all the .asc files are in your working directory.
# Load all terrain files in input directory.
raster_layers <- tibble(filename = list.files(path = getwd(),"*.asc$")) %>% 
  mutate(raster =
           map(filename, .f = ~raster::raster(rgdal::readGDAL(.)))
  ) %>% 
  pull(raster)

#Combine raster layers
raster_layers$fun <- mean
raster_mosaic <- do.call(raster::mosaic, raster_layers)

# A bit fiddly to find the exact extensions of the area you want.
e_tb <- extent(c(533125, 534375, 180000, 181250))

tower_bridge <- crop(raster_mosaic, e_tb) %>%
  raster_to_matrix() %>%
  reduce_matrix_size(0.25) 

# Static plot
tower_bridge %>%
  sphere_shade(texture = "desert") %>%
  add_water(detect_water(tower_bridge,zscale = 0.5, cutoff = 0.2,
                         min_area = length(tower_bridge)/150,
                         max_height = 3.2)) %>%
  add_shadow(ray_shade(tower_bridge, zscale = 0.5, multicore = TRUE, 
                       sunaltitude = 10, sunangle = -110),0.3) %>%
  plot_map()

# 3D plot
tower_bridge %>%
  sphere_shade(texture = "desert") %>%
  add_shadow(ray_shade(tower_bridge, zscale = 2, multicore = TRUE),0.3) %>% 
  add_water(detect_water(tower_bridge,zscale = 2, cutoff = 0.2,
                         min_area = length(tower_bridge)/150,
                         max_height = 3.2)) %>%
  plot_3d(tower_bridge, zscale = 2, 
          zoom=0.5, windowsize = 1000, 
          background = "grey50", shadowcolor = "grey20")

# Movie time!
render_movie(filename = "tb_smooth.mp4", frames = 720, fps = 60)

rgl::rgl.close()
