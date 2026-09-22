# Biometric Variation & Body Mass Modeling in Palmer Archipelago Penguins

## Overview
Understanding morphological variation and sexual dimorphism in seabirds is fundamental for ecological and physiological research. This project presents an end-to-end statistical analysis in **R** investigating body mass drivers across three Antarctic penguin species (*Pygoscelis adeliae*, *P. antarcticus*, and *P. papua*) on the Palmer Archipelago.

Rather than relying solely on descriptive statistics, this repository demonstrates a **rigorous inferential pipeline**: checking parametric assumptions before ANOVA testing, computing post-hoc pairwise comparisons, and fitting a multiple linear regression model.

## Data Source
The dataset originates from the `palmerpenguins` package, made available via [TidyTuesday (2020-07-28)](https://github.rfordatascience/tidytuesday). Measurements were collected by Dr. Kristen Gorman and the Palmer Station Long Term Ecological Research (LTER) program.

## Methodological Pipeline & Statistical Rigor

### 1. Data Tidying & Preprocessing
* Missing values were dropped (`drop_na()`) to preserve sample integrity across parametric tests.
* Categorical variables (`species`, `island`, `sex`) were converted to factors.
* Custom p-value formatting (`case_when()`) and multi-column rounding (`across()`) were applied using `dplyr` and `broom` for publication-ready outputs.

### 2. ANOVA & Diagnostic Assumption Testing
To test for significant body mass differences across species ($H_0: \mu_{Adélie} = \mu_{Chinstrap} = \mu_{Gentoo}$), formal diagnostic checks were conducted to validate parametric assumptions:
* **Normality of Residuals:** Evaluated using the **Shapiro-Wilk Test** (`shapiro.test()`) alongside Q-Q plot visual inspection (`plot(aov, which = 2)`).
* **Homogeneity of Variances (Homoscedasticity):** Tested via **Bartlett’s Test** (`bartlett.test()`).
* **Post-Hoc Analysis:** Following a statistically significant ANOVA, **Tukey’s Honest Significant Difference (HSD)** test was computed to isolate specific pairwise differences.

### 3. Multiple Linear Regression
A multiple linear regression model was built to evaluate the combined predictive effect of structural size (flipper length) and sex-based dimorphism on body mass:

$$\text{Body Mass (g)} = \beta_0 + \beta_1 (\text{Flipper Length}) + \beta_2 (\text{Sex}_{\text{male}}) + \epsilon$$

## Key Findings & Visualizations

### 1. Species-Specific Mass Distribution (ANOVA + Diagnostics)
* **Visual Representation:** A hybrid visualization combining **violin plots** (density distribution) with **embedded boxplots** (median and quartiles) to highlight distribution shapes across species.
* **Results:** Gentoo penguins (*Pygoscelis papua*) exhibit significantly higher body mass compared to both Adélie and Chinstrap penguins ($p < 0.001$), while no statistically significant mass difference was detected between Adélie and Chinstrap species ($p > 0.05$).

*(Insert your `species_weight.png` here: `![Species Body Mass](outputs/species_weight.png)`)*

#### Post-Hoc Comparison Table (Tukey HSD)
| Comparison | Estimate (g) | Conf. Low | Conf. High | Adj. P-Value |
|:---|:---:|:---:|:---:|:---:|
| Chinstrap - Adélie | 32.43 | -85.34 | 150.20 | > 0.05 (ns) |
| Gentoo - Adélie | 1375.35 | 1279.62 | 1471.09 | < 0.001 *** |
| Gentoo - Chinstrap | 1342.93 | 1214.33 | 1471.52 | < 0.001 *** |

---

### 2. Predictive Modeling of Body Mass
* **Visual Representation:** Scatter plot with dual regression trendlines split by sex, demonstrating interaction and additive effects.
* **Results:** Both flipper length ($p < 0.001$) and male sex ($p < 0.001$) are strong, positive predictors of overall body mass. Holding flipper length constant, male penguins display a consistent mass premium due to sexual dimorphism.

*(Insert your `multiple_regression.png` here: `![Multiple Regression](outputs/multiple_regression.png)`)*

