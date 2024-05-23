#######  RCKMS Analysis Code  ########

# written by: Melissa Pike  
# 6 SEPT 2023           


library(readxl)
library(openxlsx)
library(dplyr)

# SMART SHEET IMPORT:
# Specify the file path to your Excel files - This is our smartsheet

data1 <- "C:/Users/MAP0303/Downloads/RCKMS Management SmartSheet.xlsx"

# Specify the name of the worksheet (tab) you want to import
rckms_smartsheet <- "RCKMS Management SmartSheet"  

# Read the specific tab into a data frame
smartsheet_rckms <- read_excel(data1, sheet = rckms_smartsheet)


# Question: What are the statues in SmartSheet?
# Get the frequency of the "Status" column
status_freq_smart <- table(smartsheet_rckms$`RCKMS Status`)
print(status_freq_smart)

# N = 170; Drop all but Published to Production and published to test; N = 107

# DROP those that are "in_progress" , retired_from_production" and 
# Retired_from_test by selecting rows where "Status" is either 
# "published_to_production" or "published_to_test"
smart_filter <- smartsheet_rckms[smartsheet_rckms$`RCKMS Status` %in% 
                          c("Published to production", "Published to test"), ]
# Print or inspect the selected data
print(smart_filter)

status_frequency2 <- table(smart_filter$`RCKMS Status`)
print(status_frequency2)
#Answer: Published to test = 106; Published to prod = 1


# RCKMS SHEET DOWNLOADED IMPORT:
# Pull in the download from RCKMS state website
# Specify the file path to your Excel file
data <-"C:/Users/MAP0303/Downloads/RCKMS_Authoring_Status_Export_2024_02_28.xlsx"

# Specify the name of the worksheet (tab) you want to import
rckms_conditions <- "Condition List"  # Replace with the name of your sheet

# Read the specific tab into a data frame
rckms_download <- read_excel(data, sheet = rckms_conditions)

# remove [assigned to] variable
rckms_download <- rckms_download %>%
  select(-`Assigned To`)

# Question: What are the statues in rckms_download?
# Get the frequency of the "Status" column
status_frequency <- table(rckms_download$Status)
print(status_frequency)

# Answer: N = 558; In_progress = 98; Published_to_production = 1;
# Published_to_test = 108; Retired_from_production = 158; 
# Retired_from_test = 193 

# DROP those that are "in_progress" , retired_from_production" and 
# Retired_from_test by selecting rows where "Status" is either 
# "published_to_production" or "published_to_test"
rckms_filter <- rckms_download[rckms_download$Status %in% 
                          c("PUBLISHED_TO_PRODUCTION", "PUBLISHED_TO_TEST"), ]
# Print or inspect the selected data
print(rckms_filter)

# remove [assigned to] variable
rckms_filter <- rckms_filter %>%
  select(-`Assigned To`)


# Select only the variables needed to compare and create variables with the same
# names that are in rckms_download table 

#create Data Table "Smartsheet" and set as the Smartsheet data
Smartsheet <- data.frame(
  "ConditionName" = smart_filter$`RCKMS Specification Name - Primary`,
  "Version" = smart_filter$Version,
  "Status" = smart_filter$`RCKMS Status`
)

rckms_filter<- data.frame(
  "ConditionName" = rckms_filter$`Condition Name`
)

# Format the "RCKMS Status" column by replacing spaces with underscores
Smartsheet$`Status` <- gsub(" ", "_", Smartsheet$`Status`)

rckms_filter <- rckms_filter %>%
  select(-`Status`)

Smartsheet <- Smartsheet %>%
  select(-`Status`)

# Compare the Smartsheet to RCKMS_download to see what doesn't match.
# We have N = 107 in Smartsheet and N = 109 in RCKMS_filter
# Find rows in "rckms_filter that are not in "smartsheet" 

missing_rows <- anti_join(rckms_filter, Smartsheet)

left <- left_join(rckms_filter,Smartsheet)

# Print the rows missing from table2
print(missing_rows)    


library(openxlsx)

# Assuming you have a data frame named "my_data" that you want to export
write.xlsx(rckms_filter, file = "C:/Users/MAP0303/Downloads/rckms_filter.xlsx")
write.xlsx(Smartsheet, file = "C:/Users/MAP0303/Downloads/smartsheet.xlsx")




