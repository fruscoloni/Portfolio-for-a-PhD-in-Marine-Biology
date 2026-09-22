# =====================================================================
# Project: Global Analysis of Fish Production (Capture & Aquaculture)
# Author: Fruscoloni Massimo 
# Dataset: TidyTuesday (2021-10-12) - Global Seafood Production
# =====================================================================

### 1.Setup ###
# Library
library(tidyverse)
library(janitor)
library(rnaturalearth)
library(sf)
library(patchwork)
library(viridis)
# Dataset
url <- "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2021/2021-10-12/capture-fisheries-vs-aquaculture.csv"
farmed_seafood <- read_csv(url)
# Custom theme for plotting
theme_custom <- function() {
  theme_minimal(base_size = 14, base_family = "sans") %+replace%
    theme(
      plot.title = element_text(face = "bold", size = 14, margin = margin(b = 8)),
      plot.subtitle = element_text(color = "gray50", size = 10, margin = margin(b = 10)),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "gray80", linewidth = 0.2),
      legend.position = "bottom",
      axis.title = element_text(size = 10)
    )
}
# World map
map <- ne_countries(scale = "medium", returnclass = "sf")
map <- map %>% filter(admin != "Antarctica")

### 2.Tidying ###
seafood_tidy <- farmed_seafood %>%
  rename(
    Region = `Entity`,
    Aquaculture = `Aquaculture production (metric tons)`,
    Capture = `Capture fisheries production (metric tons)`
  ) %>%
  mutate(
    Aquaculture = coalesce(Aquaculture, 0),
    Capture = coalesce(Capture, 0)
  )

### 3.Wrangling ###
# Global trend over time
seafood_long <- seafood_tidy %>% drop_na(Code) %>% group_by(Year) %>%
  summarise(
    Aquaculture = sum(Aquaculture),
    Capture = sum(Capture)
  ) %>%
  pivot_longer(
    cols = c(Aquaculture, Capture), 
    names_to = "Source",                 
    values_to = "Tons"
  ) %>%
  mutate(Tons = Tons/1e6) %>%
  rename(Millions_tons = `Tons`)
# Last year proportions
last_year <- seafood_tidy %>% drop_na(Code) %>%
  filter(Year == max(Year)) %>%
  rename(Country = `Region`) %>%
  mutate(
    Total_production = Aquaculture + Capture,
    Aquaculture_prop = Aquaculture/Total_production*100,
    Aquaculture_prop = coalesce(Aquaculture_prop, 0),
    Aquaculture_prop = round(Aquaculture_prop, digits = 2)
  )

### 4.Visualization ###
# Global trend over time
global_trend <- ggplot(seafood_long, aes(x = Year, y = Millions_tons, fill = Source)) +
  geom_area(alpha = 0.6) +
  scale_fill_manual(values = c("Aquaculture" = "red2", "Capture" = "cyan3")) +
  theme_custom() +
  labs(
    tag = "A",
    title = "Global trend of fishery production over time",
    y = "Fish production (Millions of tons)"
  )
global_trend
ggsave("global_trend.png", global_trend, path = "outputs", width = 10, height = 6, dpi = 300)
# Last year proportions
last_year_map <- map %>% 
  left_join(last_year, by = c("iso_a3" = "Code"))
aquaculture_map <- ggplot(data = last_year_map) +
  geom_sf(aes(fill = Aquaculture_prop), color = "white", size = 0.2) +
  scale_fill_viridis_c(name = "Aquaculture proportion (%)", limits = c(0, 100)) +
  theme_custom() +
  theme(axis.text = element_blank(), axis.ticks = element_blank()) +
  labs(
    tag = "B",
    title = "Countries' dependance on aquaculture in the last year"
    )
aquaculture_map
ggsave("aquaculture_map.png", aquaculture_map, path = "outputs", width = 12, height = 8, dpi = 300)
#
final_plot <- global_trend | aquaculture_map
ggsave("seafood_analysis.png", final_plot, path = "outputs", width = 12, height = 7, dpi = 300)

