# =====================================================================
# Project: Coral Bleaching Simulation 
# Author: Fruscoloni Massimo 
# Dataset: Randomly originated on R 
# =====================================================================

### 1.Setup ###
# Library
library(tidyverse)
library(janitor)
library(patchwork)
library(broom)
library(lme4)
library(lmerTest)
library(broom.mixed)
library(DHARMa)
library(ggeffects)
# Datasets
coral <- read_csv("Messy_coral.csv")
env <- read_csv("Messy_env.csv")

### 2.Tidying ###
# Coral
coral_clean <- coral %>%
  rename(`Bleaching_%` = `Bleaching_percent`) %>%
  mutate(
    across(where(is.character), str_trim),
    `Bleaching_%` = str_remove(`Bleaching_%`, "%"),
    `Bleaching_%` = str_remove(`Bleaching_%`, "<"),
    `Bleaching_%` = as.numeric(`Bleaching_%`),
    Species = str_to_lower(Species),
    Species = str_replace_all(Species, "_", " "),
    Site = str_to_upper(Site),
    Site = str_replace_all(Site, "-| ", "_"),
    Date = case_when(
      str_detect(Date, "J|j|01") ~ "Jan_23",
      str_detect(Date, "F|f|02") ~ "Feb_23",
      str_detect(Date, "M|m|03") ~ "Mar_23",
      TRUE ~ "Apr_23"
    )
  )
# Environment
env_clean <- env %>%
  rename(
    Depth_m = `Depth_category`,
    Site = `Location`
    ) %>%
  mutate(
    Depth_m = if_else(str_detect(Depth_m, "Deep"), "Deep", "Shallow")
  ) %>%
  pivot_longer(
    cols = -c(Site, Depth_m),
    names_to = "Date",
    values_to = "Temperature_C"
  ) %>%
  mutate(
    Date = str_remove_all(Date, "Temp_")
  )

### 3.Wrangling ###
coral_final <- env_clean %>%
  left_join(coral_clean, by = c("Site", "Date")) %>%
  mutate(
    Thermal_stress = if_else(Temperature_C > 28.5, "High", "Normal"),
    Species = as.factor(Species),
    Species = fct_reorder(Species, `Bleaching_%`, .fun = mean, na.rm = TRUE)
  )
bleaching_summary <- coral_final %>% drop_na() %>%
  group_by(Site, Species) %>%
  summarise(
    mean = mean(`Bleaching_%`),
    std = sd(`Bleaching_%`),
    N_obs = n()
    )

### 4.Mixed model analysis ###
# Model
model <- lmer(`Bleaching_%` ~ Temperature_C + Depth_m + Species +
                (1|Site) +
                (1|Site:Colony_ID),
              data = coral_final)
summary(model)
fixed_table <- tidy(model, effects = "fixed")
random_table <- tidy(model, effects = "ran_pars")
# Diagnostics
res <- simulateResiduals(model)
plot(res)

### 5.Visualization ###
# Swarm plot
A <- ggplot(data = coral_final, aes(x = Species, y = `Bleaching_%`, color = Species)) +
  geom_jitter(alpha = 0.5) +
  stat_summary(fun.data = "mean_cl_boot", geom = "pointrange", color = "gray40", size = 0.5) +
  theme_bw() +
  theme(axis.text.x = element_blank(),
        axis.title.x = element_blank()) +
  scale_y_continuous(limits = c(0, 100)) +
  facet_wrap(~Thermal_stress) +
  labs(
    tag = "A",
    title = "Bleaching percentage across Species and Thermal Stress level",
    x = "Species",
    y = "Bleaching (%)"
  )
# Boxplot
B <- ggplot(data = coral_final, aes(x = Species, y = `Bleaching_%`, fill = Species)) +
  geom_violin(alpha = 0.8) +
  geom_boxplot(width = 0.1, fill = "white", color = "black", outlier.shape = NA) +
  theme_bw() +
  scale_y_continuous(limits = c(0, 100)) +
  coord_flip() +
  facet_wrap(~Thermal_stress) +
  theme(legend.position = "none") +
  labs(
    tag = "B",
    title = "Distribution of Bleaching percentage",
    x = "Species",
    y = "Bleaching (%)"
  )
# Mixed model
df_pred <- augment(model)
lmm_plot <- ggplot(df_pred, aes(x = Temperature_C, y = `Bleaching_%`, color = Species)) +
  geom_point(aes(shape = Depth_m), size = 2.5, alpha = 0.8) +
  geom_line(aes(y = .fitted, group = Colony_ID), alpha = 0.6, linetype = "solid") +
  scale_y_continuous(limits = c(0, 100)) +
  facet_wrap(~ Site) +
  scale_color_brewer(palette = "Dark2") +
  labs(
    tag = "C",
    title = "Observed Bleaching and Mixed-Model Fit by Site",
    x = "Temperature (°C)",
    y = "Bleaching (%)",
    shape = "Depth",
    color = "Species"
  ) +
  theme_bw(base_size = 11) +
  theme(legend.position = "bottom")
#
bleaching_plots <- A | B
ggsave("Bleaching_plots.png", bleaching_plots, path = "outputs", width = 15, height = 7, dpi = 300)
ggsave("Mixed_model.png", lmm_plot, path = "outputs", width = 10, height = 7, dpi = 300)

