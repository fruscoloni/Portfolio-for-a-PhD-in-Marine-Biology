# =====================================================================
# Project: Analysis of Body Mass in Palmer Penguins 
# Author: Fruscoloni Massimo 
# Dataset: TidyTuesday (2020-07-28) - Palmer Penguins
# =====================================================================

### 1.Setup ###
# Library
library(tidyverse)
library(janitor)
library(patchwork)
library(broom)
# Dataset
url <- "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2020/2020-07-28/penguins.csv"
penguins <- read_csv(url)
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

### 2.Tidying ###
penguins_tidy <- penguins %>% drop_na() %>%
  mutate(
    species = as.factor(species),
    island = as.factor(island),
    sex = as.factor(sex)
  ) %>%
  mutate(weight_class = if_else(body_mass_g > 4000, "Heavy", "Light"))

### 3.Body mass dimorphism between species ###
anova <- aov(body_mass_g ~ species, data = penguins_tidy)
summary(anova)
# Diagnostics
res <- residuals(anova)
shapiro.test(res)
plot(anova, which = 2)
bartlett.test(body_mass_g ~ species, data = penguins_tidy)
# The assumptions are respected
pairwise_comparisons <- TukeyHSD(anova)
pairwise_table <- tidy(pairwise_comparisons)
pairwise_table <- pairwise_table %>%
  select(-term) %>%
  mutate(
    across(where(is.numeric) & !adj.p.value, ~ round(.x, digits = 2)),
    adj.p.value = case_when(
      adj.p.value >= 0.05 ~ "> 0.05",
      adj.p.value >= 0.01 ~ "< 0.05 *",
      adj.p.value >= 0.001 ~ "< 0.01 **",
      TRUE ~ "< 0.001 ***" 
    )
  )

### 4.Multiple linear regression between body mass, flipper lenght & sex ###
regression <- lm(body_mass_g ~ flipper_length_mm + sex, data = penguins_tidy)
summary(regression)
plot(regression)
regression_table <- tidy(regression)
regression_table <- regression_table %>%
  mutate(
    across(where(is.numeric) & !p.value, ~ round(.x, digits = 2)),
    term = str_replace(term, "sexmale", "sex_male"),
    p.value = case_when(
      p.value >= 0.05 ~ "> 0.05",
      p.value >= 0.01 ~ "< 0.05 *",
      p.value >= 0.001 ~ "< 0.01 **",
      TRUE ~ "< 0.001 ***" 
    )
  )

### 5.Visualization ###
species_weight <- ggplot(penguins_tidy, aes(x = species, y = body_mass_g, fill = species)) +
  geom_violin(alpha = 0.5) +
  geom_boxplot(width = 0.2, fill = "white", color = "black", outlier.shape = NA) +
  theme_custom() +
  theme(legend.position = "none") +
  labs(
    tag = "A",
    title = "Distribution of body mass across species",
    x = "Species",
    y = "Body mass (g)"
  )
ggsave("species_weight.png", species_weight, path = "outputs", width = 10, height = 8, dpi = 300)
#
multiple_regression <- ggplot(penguins_tidy, aes(x = flipper_length_mm, y = body_mass_g, color = sex)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm") +
  theme_custom() +
    labs(
      tag = "B",
      title = "Predicting body mass by flipper length and sex",
      x = "Flipper length (mm)",
      y = "Body mass (g)"
    )
ggsave("multiple_regression.png", multiple_regression, path = "outputs", width = 10, height = 7, dpi = 300)
#
final_plot <- species_weight | multiple_regression
ggsave("weight_analysis.png", final_plot, path = "outputs", width = 13, height = 6, dpi = 300)


write.csv(penguins, "Palmer_Penguins.csv")