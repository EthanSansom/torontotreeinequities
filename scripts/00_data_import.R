#### Preamble ####
# Purpose: Download data on Toronto's street trees and neighbourhood profiles
# Author: Ethan Sansom
# Contact: ethan.sansom@mail.utotoronto.ca
# Date: 2022-03-05
# Pre-requisites: None

# Load Packages -------------------------------------
library(opendatatoronto)   # For getting data
library(tidyverse)
library(here)              # For file path management

# Import Data ---------------------------------------
# Load Toronto city-tree data
raw_tree_data <-
  list_package_resources("6ac4569e-fd37-4cbc-ac63-db3624c5f6a2") |> 
  filter(name == "Alternate File_Street Tree Data_WGS84.csv") |> 
  get_resource()

# Load Toronto neighbourhood map data (WGS84 Projection)
raw_neighbourhood_map_data <-
  list_package_resources("4def3f65-2a65-4a4f-83c4-b2a4aed72d46") |>
  filter(name == "Neighbourhoods") |> 
  get_resource()

# Load Toronto neighbourhood census data
raw_neighbourhood_census_data <-
  list_package_resources("6e19a90f-971c-46b3-852c-0c48c436d1fc") |> 
  filter(name == "neighbourhood-profiles-2016-csv") |> 
  get_resource()

# Save city-tree data (Warning: "raw_tree_data.csv" is 109.4 MB)
write_csv(raw_tree_data, file = here("inputs/data/raw_tree_data.csv"))

# Save ward map data
write_rds(raw_neighbourhood_map_data, file = here("inputs/data/raw_neighbourhood_map_data.rds"))

# Save census data
write_csv(raw_neighbourhood_census_data, file = here("inputs/data/raw_neighbourhood_census_data.csv"))

