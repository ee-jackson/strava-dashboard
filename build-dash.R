library("rStrava")
library("tidyverse")
library("googlePolylines")
library("sf")
source("secrets.R")
library("ggmap")

# Strava key
app_name <- "athlete-dashboard"
app_client_id <- "136172"
app_secret <- APP_SECRET

# create strava token
my_token <- httr::config(token = strava_oauth(app_name, app_client_id, app_secret, app_scope = 'read_all,activity:read_all'))

# download strava data
my_acts <- get_activity_list(my_token)

length(my_acts)
saveRDS(my_acts, "activities-20240927.rds")
# compile activities into a tidy dataframe
my_acts <- compile_activities(my_acts)

# have a look at the dataframe
dplyr::glimpse(my_acts)

# columns to keep
desired_columns <- c('distance', 'elapsed_time', 'moving_time', 'start_date', 'start_date_local', 'type', 'map.summary_polyline', 'location_city', 'upload_id')

# keep only desired columns
my_acts2 <- dplyr::select(my_acts, any_of(desired_columns))

# transformations ####
my_acts <- mutate(my_acts,
                  activity_no = seq(1,n(), 1),
                  elapsed_time = elapsed_time/60/60,
                  moving_time = moving_time/60/60,
                  date = gsub("T.*$", '', start_date) %>%
                    as.POSIXct(., format = '%Y-%m-%d'),
                  EUdate = format(date, '%d/%m/%Y'),
                  month = format(date, "%m"),
                  day = format(date, "%d"),
                  year = format(date, "%Y")) %>%
  mutate(., across(c(month, day), as.numeric)) %>%
  filter(!is.na(start_latlng1)) %>%
  filter(type == "Run")


coords_all <-
  my_acts %>%
  mutate(coords = googlePolylines::decode(map.summary_polyline)) %>%
  unnest(coords)

coords_all %>%
  filter(year == year(Sys.Date())) %>%
  ggplot(aes(x = lon, y = lat)) +
  geom_path(alpha = 0.5, colour = "darkorange2") +
  theme_void() +
  facet_wrap(~id, ncol = 4)



# map ---------------------------------------------------------------------



coords_all %>%
  st_as_sf(coords = c('lon', 'lat')) %>%
  st_set_crs(
    "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0"
  ) -> gg_data

# get a basemap

bbox <-
  make_bbox(c(
    -1.37,
    -1.17
  ),
  c(
    51.72,
    51.82
  ))


ox_basemap <- ggmap::get_map(bbox, zoom = 13,
                                 force = TRUE,
                                 source = "stadia",
                                 maptype = "alidade_smooth")

# routes on oxford map

ggmap(ox_basemap) +
  geom_path(aes(x = lon, y = lat, group = id), data = coords_all,
            alpha = 0.5, colour = "darkorange2") +
  theme_void(base_size = 10) -> route_map

ggsave("oxford_route_map.png", route_map)
