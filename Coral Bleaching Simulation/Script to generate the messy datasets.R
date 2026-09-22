# Script to generate the "messy" datasets

set.seed(42)

# Basic dataset
colonies <- paste0("Col_", 1:40)
sites <- rep(c("site_a", "site_b", "site_c", "site_d"), each = 10)
months <- c("Jan-23", "Feb-23", "Mar-23", "Apr-23")
species_base <- c("Acropora cervicornis", "Montipora capitata", "Porites lobata")
messy_coral <- expand.grid(Colony_ID = colonies, Date = months)
messy_coral$Site <- rep(sites, times = 4)
messy_coral$Species <- sample(species_base, 160, replace = TRUE)

# Introducing some disorder
messy_coral$Species[c(5, 23, 89, 142)] <- c("acropora cervicornis ", "Montipora_capitata", "porites LOBATA", "Acropora_cervicornis")
messy_coral$Date <- as.character(messy_coral$Date)
messy_coral$Date[c(12, 45, 112)] <- c("01_2023", "feb 2023", "MARCH-23")
messy_coral$Site[c(2, 53, 106)] <- c("SITE_A", "site b", "Site-C")

# Adding bleaching variable 
base_bleach <- rnorm(160, mean = 20, sd = 10) + as.numeric(as.factor(messy_coral$Site))*5
messy_coral$Bleaching_percent <- round(base_bleach, 1)
messy_coral$Bleaching_percent <- paste0(messy_coral$Bleaching_percent, "%")
messy_coral$Bleaching_percent[c(8, 34, 76, 120)] <- c("<5", "N/D", " 15.2 % ", "not recorded")

# Environmental meta-dataset
messy_env <- data.frame(
  Location = c("SITE_A", "SITE_B", "SITE_C", "SITE_D"),
  Depth_category = c("Shallow (5m)", "Deep (15m)", "Shallow (4m)", "Deep (20m)"),
  Temp_Jan_23 = c(26.1, 25.5, 26.3, 24.8),
  Temp_Feb_23 = c(27.5, 26.2, 27.8, 25.4),
  Temp_Mar_23 = c(29.1, 27.5, 29.5, 26.8),
  Temp_Apr_23 = c(29.8, 28.1, 30.2, 27.3)
)

# Exporting
write.csv(messy_coral, "Messy_coral.csv", row.names = FALSE)
write.csv(messy_env, "Messy_env.csv", row.names = FALSE)

