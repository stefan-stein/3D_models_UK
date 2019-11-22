
# University of Warwick ---------------------------------------------------

# Get the data from here:
# https://data.gov.uk/dataset/5f6f7d5b-3f4c-4476-bfb8-cda490c9cf0e/lidar-composite-dtm-50cm
# You will have to download tiles SP37nw and SP27ne

library(tidyverse)
library(rayshader)
library(raster)

# Assuming all the .asc files are in your working directory
raster_layers <- tibble(filename = list.files(path = getwd(),"*.asc$")) %>% 
  mutate(raster =
           map(filename, .f = ~raster::raster(rgdal::readGDAL(.)))
  ) %>% 
  pull(raster)

# Combine raster layers
raster_layers$fun <- mean
raster_mosaic <- do.call(raster::mosaic, raster_layers)

# A bit fiddly to find the exact extensions of the area you want.
e <- extent(c(429000, 431000, 275000, 277000))
full_raster_cropped <- crop(raster_mosaic, e) %>%
  raster_to_matrix() %>%
  reduce_matrix_size(0.5)

full_raster_cropped %>%sphere_shade(texture = "imhof4") %>%
  add_shadow(ray_shade(full_raster_cropped, zscale = 0.5, multicore = TRUE, 
                       sunaltitude = 30, sunangle = -110, lambert = FALSE), 0.3) %>%
  add_shadow(lamb_shade(full_raster_cropped, zscale = 0.5, sunaltitude = 30, sunangle = -110), max_darken = 0.5)%>%
  add_shadow(ambient_shade(full_raster_cropped, multicore = TRUE), max_darken = 0.1) %>%
  plot_3d(full_raster_cropped, zscale = 0.5,windowsize = c(1000,1000),
          background = "grey30", shadowcolor = "grey5", water = FALSE)

render_label(full_raster_cropped, "Cannon Park", x = 710, y = 140, z = 150, linecolor = "white",
             textcolor = "white", zscale = 1, clear_previous = TRUE)
render_label(full_raster_cropped, "Zeeman", x = 530, y = 340, z = 150, linecolor = "white",
             textcolor = "white", zscale = 1)
render_label(full_raster_cropped, "WMG", x = 490, y = 390, z = 150, linecolor = "white",
             textcolor = "white", zscale = 1)
render_label(full_raster_cropped, "WBS", x = 340, y = 460, z = 150, linecolor = "white",
             textcolor = "white", zscale = 1)

render_camera(theta = 30, phi = 30, zoom = 0.5)
render_movie(filename = "campus_smooth.mp4", frames = 720, fps = 60)
render_snapshot(filename = "campus_zoom_label.png")

rgl::rgl.clear()
