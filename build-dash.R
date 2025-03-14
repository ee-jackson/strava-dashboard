#!/usr/bin/env Rscript

library("rStrava")
library("tidyverse")
library("sf")
library("googlePolylines")
library("ggmap")

source("secrets.R")

# create strava token
my_token <-
  httr::config(token = strava_oauth(
    app_name = APP_NAME,
    app_client_id = APP_CLIENT_ID,
    app_secret = APP_SECRET,
    app_scope = "read_all,activity:read_all"))

# download strava data + make tidy
my_acts <-
  get_activity_list(my_token) %>%
  rStrava::compile_activities()

# columns to keep
desired_columns <- c("upload_id",
                     "activity_no",
                     "average_heartrate",
                     "max_heartrate",
                     "average_speed",
                     "max_speed",
                     "distance",
                     "elapsed_time",
                     "moving_time",
                     "elev_high",
                     "elev_low",
                     "total_elevation_gain",
                     "start_date",
                     "start_date_local",
                     "type",
                     "map.summary_polyline")

# keep only desired columns
my_acts <-
  my_acts %>%
  filter(manual == "FALSE" & type == "Run") %>%
  dplyr::select(any_of(desired_columns))

# transformations
my_acts <-
  my_acts %>%
  mutate(
    activity_no = seq(1,n(), 1),
    elapsed_time = elapsed_time/60/60,
    moving_time = moving_time/60/60,
    date = gsub("T.*$", "", start_date) %>%
      as.POSIXct(., format = "%Y-%m-%d"),
    EUdate = format(date, '%d/%m/%Y'),
    month = format(date, "%m"),
    day = format(date, "%d"),
    year = format(date, "%Y")) %>%
  mutate(., across(c(month, day), as.numeric))

coords_all <-
  my_acts %>%
  mutate(coords = googlePolylines::decode(map.summary_polyline)) %>%
  unnest(coords)


# oxford map --------------------------------------------------------------

register_stadiamaps(Sys.getenv("GGMAP_STADIAMAPS_API_KEY"), write = FALSE)

coords_all %>%
  sf::st_as_sf(coords = c("lon", "lat")) %>%
  sf::st_set_crs(
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

route_map <-
  ggmap(ox_basemap) +
  geom_path(aes(x = lon, y = lat, group = upload_id),
            data = coords_all,
            alpha = 0.5, colour = "darkorange2") +
  theme_void(base_size = 10)

ggsave("oxford_route_map.png",
       route_map,
       width = 20,
       height = 15,
       dpi = 300,
       units = "cm")


# facet maps --------------------------------------------------------------

facet_map <-
  coords_all %>%
  ggplot() +
  ggplot2::geom_path(aes(lon, lat, group = upload_id),
                     linewidth = 0.35,
                     lineend = "round") +
  ggplot2::facet_wrap(~reorder(upload_id, date), scales = "free") +
  ggplot2::theme_void() +
  ggplot2::theme(panel.spacing = ggplot2::unit(0, "lines"),
                 strip.background = ggplot2::element_blank(),
                 strip.text = ggplot2::element_blank(),
                 plot.margin = ggplot2::unit(rep(1, 4), "cm"),
                 legend.position = "bottom")

ggsave("facet_map.png",
       facet_map,
       width = 20,
       height = 30,
       dpi = 300,
       units = "cm")


# heatmap -----------------------------------------------------------------

unit_per_date <-
  my_acts %>%
  group_by(date, EUdate) %>%
  summarise(
    distance = sum(distance, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  tidyr::complete(
    date = seq(min(date), max(date), by = "1 day"),
    fill = list(distance = NA)
  ) %>%
  mutate(year = year(date))


calendar_heatmap <-
  unit_per_date %>%
  mutate(
    week = week(date),
    wday = wday(date)
  ) %>%
  ggplot(
    aes(
      x = week,
      y = wday
    )
  ) +
  geom_tile(
    aes(fill = distance),
    linewidth = 0.25
  ) +
  coord_fixed() +
  scale_fill_continuous(
    name = "km",
    low = "#FFE6D6",
    high = "#FE5502",
    na.value = "#f9f8f8"
  ) +
  facet_wrap(~year, ncol = 1) +
  scale_x_continuous(
    breaks = seq(1, 52, 53/12),
    labels = month.abb,
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    trans = "reverse",
    breaks = c(1:7),
    labels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"),
    expand = c(0, 0)
  ) +
  theme(line = element_blank(),
        rect = element_blank(),
        axis.ticks = element_blank(),
        axis.title = element_blank(),
        axis.ticks.length = unit(0, "pt"),
        axis.minor.ticks.length = unit(0, "pt"),
        legend.box = NULL,
        legend.key.size = unit(1.2, "lines"),
        legend.position = "right",
        legend.text = element_text(size = rel(0.8))
  )

ggsave("calendar_heatmap.png",
       calendar_heatmap,
       width = 20,
       height = 25,
       dpi = 300,
       units = "cm")

#inspo:
#https://marcusvolz.com/strava/
#https://github.com/marcusvolz/strava/blob/master/R/plot_calendar.R
