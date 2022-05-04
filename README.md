# torontotreeinequities

### Description
An analysis of the relationship between Toronto neighbourhoods' street tree density, income,  and visible minority population, utilizing spatial autoregression methods.

### Abstract
Urban trees are associated with significant ecological, public health, and economic benefits in cities across North America. These benefits, however, are inequitibly afforded to racialized communities and low income communities, which have disproportionaly little access to urban forestry. This paper utilizes a spatial autoregressive model of Toronto’s 140 neighbourhoods to investigate the correlation between neighbourhood median household income, visible minority population, and street tree density within the city. The presence of several visible minority groups, namely Chinese, South Asian, and Filipino populations, are shown to be strongly and significantly negatively correlated with neighbourhood street tree density.

# File Structure
The `scripts` folder contains two files, `00_data_import.R` and `01_data_cleaning.R` which import and clean the majority of the data used for this analysis. The data saved by these scripts are contained in the `inputs/data` folder. The only file in the `data` folder not created by these scripts is `neighbourhood_income_2016.csv`, which contains the 2016 median household after-tax income of each of Toronto's 140 neighbourhoods. The folder `outputs/paper` contains an R markdown file and a .bib file which output the final paper as a PDF. All regression models, tables, and plots are created by the file `paper.Rmd`. Additionaly, `outputs/paper` contains a PDF copy of the final paper itself.
