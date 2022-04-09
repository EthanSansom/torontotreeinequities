#### Preamble ####
# Purpose: Clean Toronto street tree and ward map data
# Author: Ethan Sansom
# Contact: ethan.sansom@mail.utotoronto.ca
# Date: 2022-03-07
# Pre-requisites:
# - run "00_data_import.R" script

# Load Packages ----------------------------------------------------------------
library(tidyverse)
library(dplyr)
library(stringr)   # For processing strings
library(janitor)   # For cleaning data
library(sf)        # For working with Shapefile and Polygon objects
library(here)      # For file path management

# Clean Toronto Street Tree Data -----------------------------------------------
# Load raw data
raw_tree_data <- read_csv(here("inputs/data/raw_tree_data.csv"))

# Select and rename columns needed for analysis 
clean_tree_data <- 
  clean_names(raw_tree_data) |>
  select(x_id, dbh_trunk, common_name, geometry) |>
  rename(
    "tree_id" = x_id, 
    "trunk_diameter" = dbh_trunk, # diameter of trunk in inches at 2 meters height
    "coordinates" = geometry      # string containing tree's latitude and longitude
  )

# Recode trunk diameters of 0 as NA
# line coded with help from: https://stackoverflow.com/questions/11036989/replace-all-0-values-to-na
clean_tree_data$trunk_diameter[clean_tree_data$trunk_diameter == 0] <- NA

# Remove suffix and prefix from observations in the coordinates column
# Resulting observations are strings of the form "longitude, latitude"
clean_tree_data$coordinates <-
  clean_tree_data$coordinates |>
  str_replace(
    pattern = fixed("{u'type': u'Point', u'coordinates': ("), 
    replacement = ""
  ) |>
  str_replace(
    pattern = fixed(")}"), 
    replacement = ""
  )

# Create numeric longitude and latitude variables
clean_tree_data <-
  clean_tree_data |>
  separate(
    col = coordinates,
    into = c('longitude', 'latitude'),
    sep = ", "
  ) |>
  mutate(
    longitude = as.numeric(longitude),
    latitude = as.numeric(latitude)
  )

# Create dummy variable for trunk_diameter greater than 3rd quartile, less than 1st quartile
clean_tree_data <-
  clean_tree_data |>
  mutate(
    is_large = trunk_diameter > quantile(trunk_diameter, 0.75, na.rm = TRUE),
    is_small = trunk_diameter < quantile(trunk_diameter, 0.25, na.rm = TRUE)
  )

# Save cleaned data
write_csv(clean_tree_data, here("inputs/data/clean_tree_data.csv"))

# Clean Neighbourhood Census Data ----------------------------------------------
# Load raw data
raw_neighbourhood_census_data <- read_csv(here("inputs/data/raw_neighbourhood_census_data.csv"))

# Clean names and remove unneeded columns
clean_neighbourhood_census_data <-
  clean_names(raw_neighbourhood_census_data) |>
  select(-c(id, category, topic, data_source))

# Transpose the census data, re-clean names
clean_neighbourhood_census_data <-
  clean_neighbourhood_census_data |>
  t() |>
  as.tibble() |>
  row_to_names(row_number=1) |>
  clean_names() |>
  rename("code" = neighbourhood_number)

# Select desired census variables
clean_neighbourhood_census_data <-
  clean_neighbourhood_census_data |>
  select(
    code,
    population_2016,
    population_density_per_square_kilometre,
    land_area_in_square_kilometres,
    # Housing Controls
    occupied_private_dwellings_by_structural_type_of_dwelling,
    apartment_in_a_building_that_has_five_or_more_storeys,
    apartment_in_a_building_that_has_fewer_than_five_storeys,
    apartment_or_flat_in_a_duplex,
    semi_detached_house,
    other_single_attached_house,
    single_detached_house,
    row_house,
    movable_dwelling,
    # Neighbourhood Age Proxy
    total_occupied_private_dwellings_by_period_of_construction_25_percent_sample_data,
    x1960_or_before,
    x1961_to_1980,
    x1981_to_1990_2,
    x1991_to_2000_2,
    x2001_to_2005_2,
    x2006_to_2010_2,
    x2011_to_2016_2,
    # Household Composition
    average_household_size,
    persons_living_alone_per_cent,
    # Income
    prevalence_of_low_income_based_on_the_low_income_measure_after_tax_lim_at_percent,
    total_economic_family_income_decile_group_for_the_population_in_private_households_100_percent_data,
    ends_with("decile"),
    # Visible Minority Status
    total_visible_minority_for_the_population_in_private_households_25_percent_sample_data,
    total_visible_minority_population,
    chinese,
    south_asian,
    black,
    latin_american,
    filipino,
    arab,
    southeast_asian,
    west_asian,
    korean_4,
    japanese_4,
    visible_minority_n_i_e,
    multiple_visible_minorities,
    not_a_visible_minority
  )

# Coerce vars from character to numeric
clean_neighbourhood_census_data <-
  clean_neighbourhood_census_data |>
  mutate(across(everything(), ~gsub(",|%", "", .))) |>
  mutate(across(everything(), as.numeric)) |>
  filter(!is.na(code))

# Rename variables by group
clean_neighbourhood_census_data <-
  clean_neighbourhood_census_data |>
  rename_with(~ gsub("_4|_2", "", .x)) |>
  # Housing Size
  rename_with(
    ~ paste("housing_", ., sep =""), 
    c(apartment_in_a_building_that_has_five_or_more_storeys,
      apartment_in_a_building_that_has_fewer_than_five_storeys,
      apartment_or_flat_in_a_duplex,
      semi_detached_house,
      other_single_attached_house,
      single_detached_house,
      row_house,
      movable_dwelling)
    ) |>
  # Visible Minority Status
  rename_with(
    ~ paste("vm_", ., sep =""), 
    c(chinese,
      south_asian,
      black,
      latin_american,
      filipino,
      arab,
      southeast_asian,
      west_asian,
      korean,
      japanese,
      visible_minority_n_i_e,
      multiple_visible_minorities,
      not_a_visible_minority)
  )

# Create proportional variables for comparison across neighbourhoods
proportional_neighbourhood_census_data <-
  clean_neighbourhood_census_data |>
  # Visible Minority Status
  mutate(
    vm_all_total = rowSums(across(starts_with("vm")), na.rm = T),
    vm_min_total = vm_all_total - vm_not_a_visible_minority
  ) |>
  mutate(across(starts_with("vm"), ~ . / vm_all_total)) |>
  # Housing Size
  mutate(
    housing_total = rowSums(across(starts_with("housing")), na.rm = T)
  ) |>
  mutate(across(starts_with("housing"), ~ . / housing_total)) |>
  # Housing Age
  mutate(
    housing_age_total = rowSums(across(starts_with("x")), na.rm = T)
  ) |>
  mutate(across(starts_with("x"), ~ . / housing_age_total)) |>
  # Economic Status Deciles
  mutate(
    eco_deciles_total = rowSums(across(starts_with("in_")), na.rm = T)
  ) |>
  mutate(across(starts_with("in_"), ~ . / eco_deciles_total))

# Drop unneeded variables
proportional_neighbourhood_census_data <-
  proportional_neighbourhood_census_data |>
  select(
    -c(
      occupied_private_dwellings_by_structural_type_of_dwelling,
      total_occupied_private_dwellings_by_period_of_construction5_percent_sample_data,
      total_economic_family_income_decile_group_for_the_population_in_private_households_100_percent_data,
      total_visible_minority_for_the_population_in_private_households5_percent_sample_data,
      total_visible_minority_population,
      vm_all_total,
      housing_total,
      housing_age_total,
      eco_deciles_total
      )
    )

# Save cleaned map data
write_csv(clean_neighbourhood_census_data, here("inputs/data/clean_neighbourhood_census_data.csv"))
write_csv(proportional_neighbourhood_census_data, here("inputs/data/proportional_neighbourhood_census_data.csv"))

# Clean Neighbourhood Map Data -------------------------------------------------
# Load raw data
raw_neighbourhood_map_data <- read_rds(here("inputs/data/raw_neighbourhood_map_data.rds"))

# Select and rename columns needed for analysis
clean_neighbourhood_map_data <-
  clean_names(raw_neighbourhood_map_data) |>
  select(area_long_code, area_name, shape_area, geometry, classification) |>
  rename(
    "neighbourhood" = area_name,
    "code" = area_long_code,
  )

# Coerce code to numeric, remove bracketed text from neighbourhood
clean_neighbourhood_map_data <-
  clean_neighbourhood_map_data |>
  transmute(
    code = as.numeric(code),
    neighbourhood = trimws(gsub("\\(.*)", "", neighbourhood), which = c("both"))
  )

# Create neighbourhood area variable
clean_neighbourhood_map_data <-
  clean_neighbourhood_map_data |>
  mutate(area_sq_km = as.numeric(st_area(geometry)) / 1000**2)

# Save cleaned map data
write_rds(clean_neighbourhood_map_data, here("inputs/data/clean_neighbourhood_map_data.rds"))


