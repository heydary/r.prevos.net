## Pacific island hopping
## https://lucidmanager.org/pacific-island-hopping/

## Init
library(ggmap)
api <- readLines("google.api") # Text file with the API key
register_google(key = api)
library(ggplot2)
library(ggrepel)
library(geosphere)
library(tidyverse)

## Read flight list and airport list
flights <- read_csv("PacificFlights.csv")
f <- "pacific_airports.csv"
if (file.exists(f)) {
    airports <- read.csv(f)
} else
    airports <- data.frame(airport = NA, lat = NA, lon = NA)

## Lookup coordinates for new airports
all_airports <- unique(c(flights$From, flights$To))
new_airports <- all_airports[!(all_airports %in% airports$airport)]
new_airports

while (length(new_airports) != 0) {
    coords <- geocode(new_airports)
    temp_airports <- data.frame(airport = new_airports, coords)
    airports <- rbind(airports, temp_airports) %>%
        filter(!is.na(lat), !is.na(lon))
    new_airports <- all_airports[!(all_airports %in% airports$airport)]
}

write_csv(airports, f)

## Add coordinates to flight list
flights <- merge(flights, airports, by.x="From", by.y="airport")
flights <- merge(flights, airports, by.x="To", by.y="airport")

## Remove country names
airports$airport <- as.character(airports$airport)
comma <- regexpr(",", airports$airport)
airports$airport[which(comma > 0)] <- substr(airports$airport[which(comma > 0)], 1, comma[comma > 0] - 1)

## Pacific centric
flights$lon.x[flights$lon.x < 0] <- flights$lon.x[flights$lon.x < 0] + 360
flights$lon.y[flights$lon.y < 0] <- flights$lon.y[flights$lon.y < 0] + 360
airports$lon[airports$lon < 0] <- airports$lon[airports$lon < 0] + 360

## Plot flight routes
worldmap <- borders("world2", fill = "grey") # create a layer of borders
ggplot() + worldmap + 
    geom_point(data=airports, aes(x = lon, y = lat), col = "#970027") + 
    geom_text_repel(data=airports, aes(x = lon, y = lat, label = airport), col = "black", size = 2, segment.color = NA) + 
    geom_curve(data=flights, aes(x = lon.x, y = lat.x, xend = lon.y, yend = lat.y, col = Airline), size = 1, curvature = .2) +
    xlim(90, 300) + ylim(-50, 50) + 
    theme_void()

ggsave("pacifc_flights.png", dpi = 300)

## Network Analysis
library(igraph)
g <- graph_from_edgelist(as.matrix(flights[,1:2]), directed = FALSE)
par(mar = rep(0, 4))
plot(g, layout = layout.fruchterman.reingold, vertex.size=0)
shortest_paths(g, "Auckland", "Saipan")

