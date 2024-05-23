#######  RCKMS Code for Creating .CSV tracking file ########

# written by: Melissa Pike  
# MARCH 26, 2024          
 
# add libraries
library(readxl)
library(openxlsx)
library(dplyr)
library(lubridate)
library(stringr)

# This requires that you download the most recent XLSX Authoring Status Report 
# import data downloaded from RCKMS
# Specify the file path to the downloaded Authoring Status Report

rckms_download <- 
  "C:/Users/MAP0303/Downloads/RCKMS_Authoring_Status_Export_2024_03_26.xlsx"

# Specify the name of the worksheet (tab) you want to import
tab_conditionslist <- "Condition List"  

# Read the specific tab into a data frame
rckms_new <- read_excel(rckms_download, sheet = tab_conditionslist)

# Create a date of download from RCKMS
RCKMS_dt <- Sys.Date()
rckms_new$RCKMS_dt <- RCKMS_dt
RCKMS_dt <- format(Sys.Date(), "%m/%d/%Y")

# Extract the XX.X format from the Version column
filtered_rckms_new <- rckms_new %>%
  mutate(Version_WA = str_extract(Version, "\\d+(\\.\\d+)?"))

# Filter rows where the status is "PUBLISHED_TO_TEST" and PUBLISHED_TO_PROD
filtered_rckms_new2 <- filtered_rckms_new %>%
  filter(Status == "PUBLISHED_TO_TEST"| Status == "PUBLISHED_TO_PRODUCTION")

# Update condition names to match those in Step 2 output.

filtered_rckms_new2 <- filtered_rckms_new2 %>%
  mutate(Condition_Name = case_when(
    `Condition Name` == "Japanese encephalitis virus disease" ~ "Japanese encephalitis virus (JEV) disease",
    TRUE ~ `Condition Name`
  ))

# Reorganize the variables
rckms_WA_State <- filtered_rckms_new2 %>%
  select(Condition_Name, Version_WA, RCKMS_dt, Status)

###########################################################################
# STEP 2:
# Next download the most recent list of versions from RCKMS: 
# https://www.rckms.org/content-repository/
# https://www.rckms.org/conditions-available-in-rckms/

rckms_updates <- 
  "C:/Users/MAP0303/Downloads/RCKMS-Consolidated-Content-Release-Notes_20231006.xlsx"

# Specify the name of the worksheet (tab) you want to import
tab_updates <- "Condition List"  

# Read the specific tab into a data frame
rckms_updates2 <- read_excel(rckms_updates, sheet = tab_updates)

# Rename Content Release Vaiables
rckms_updates3 <- rckms_updates2 %>%
  rename("Content Release 1" = "Content Release 1 -",
         "Content Release 2" = "Content Release 2 - 6/30/19",
         "Content Release 3" = "Content Release 3 - 1/10/20", 
         "Content Release 4" = "Content Release 4 - 6/8/20",
         "Content Release 5" = "Content Release 5 - 1/29/21",
         "Content Release 6" = "Content Release 6 - 6/9/21",
         "Content Release 7" = "Content Release 7 - 1/28/22",
         "Content Release 8" = "Content Release 8 - 6/15/22",
         "Content Release 9" = "Content Release 9 - 02/03/2023",
         "Content Release 10" = "Content Release 10 - 06/14/2023")

# Assign names to the unnamed columns
names(rckms_updates3)[12:14] <- c("Content Release 11", "Content Release 12", 
                                 "Content Release 13")

# delete rows in 'Scheduled Releases that we don't need
# Define conditions to filter rows
condition1 <- !is.na(rckms_updates3$`Scheduled Releases`)
condition2 <- !grepl("These conditions have been included in Emergent Releases", rckms_updates3$`Scheduled Releases`, fixed = TRUE)
condition3 <- !grepl("These conditions have been included in Off-Scheduled Releases", rckms_updates3$`Scheduled Releases`, fixed = TRUE)
condition4 <- !grepl("Emergent Releases", rckms_updates3$`Scheduled Releases`, fixed = TRUE)
condition5 <- !grepl("Off-Schedule Releases", rckms_updates3$`Scheduled Releases`, fixed = TRUE)

rckms_updates3_filtered <- rckms_updates3 %>%
  filter(condition1 & condition2 & condition3 & condition4 & condition5)

# Rename Variables to match what is in the filtered_rckms_new so we can join
rckms_updates4 <- rckms_updates3_filtered %>%
  mutate(Scheduled_Release_Modified = `Scheduled Releases`) %>%
  mutate(Scheduled_Releases = case_when(
    Scheduled_Release_Modified == "COVID-19**^^" ~ "COVID-19",
    Scheduled_Release_Modified == "Gonorrhea^^" ~ "Gonorrhea",
    Scheduled_Release_Modified == "Hepatitis C Virus Infection^^" ~ "Hepatitis C Virus Infection",
    Scheduled_Release_Modified == "Influenza-Associated Mortality^^" ~ "Influenza-Associated Mortality",
    Scheduled_Release_Modified == "Influenza-associated pediatric mortality^^" ~ "Influenza-associated pediatric mortality",
    Scheduled_Release_Modified == "Influenza-like Illness (ILI)^^" ~ "Influenza-like Illness (ILI)",
    Scheduled_Release_Modified == "Novel Influenza A Virus Infection^^" ~ "Novel Influenza A Virus Infection",
    Scheduled_Release_Modified == "Orthopoxvirus Disease**" ~ "Orthopoxvirus Disease",
    Scheduled_Release_Modified == "Syphilis^^" ~ "Syphilis",
    Scheduled_Release_Modified == "Mpox**^^" ~ "Mpox",
    Scheduled_Release_Modified == "Influenza^^" ~ "Influenza",
    Scheduled_Release_Modified == "Tickborne relapsing fever (TBRF)" ~ "Tickborne relapsing fever (TBRF)",
    Scheduled_Release_Modified == "Respiratory Syncytial Virus (RSV)^^" ~ "Respiratory Syncytial Virus",
    Scheduled_Release_Modified == "Respiratory Syncytial Virus (RSV)-Associated Mortality^^" ~ "Respiratory Syncytial Virus (RSV)-Associated Mortality",
    Scheduled_Release_Modified == "Influenza-like-Illness (ILI)^^" ~ "Influenza-like-Illness (ILI)",
    TRUE ~ as.character(Scheduled_Release_Modified)
  )) %>%
  select(-Scheduled_Release_Modified)

# Order the dataframe
rckms_updt_ordered <- rckms_updates4 %>%
  select(Scheduled_Releases, `Content Release 1`, `Content Release 2`,  
         `Content Release 3`, `Content Release 4`,  `Content Release 5`,  
         `Content Release 6`,  `Content Release 7`, `Content Release 8`,  
         `Content Release 9`,  `Content Release 10`,  `Content Release 11`,
         `Content Release 12`,  `Content Release 13`) %>%
  arrange(Scheduled_Releases)

# Choose the most recent version
RCKMS_Version <- rckms_updt_ordered %>%
  rowwise() %>%
  mutate(RCKMS_Recent_Version = max(na.omit(as.numeric(str_extract_all(across
    (`Content Release 1`:`Content Release 13`), "\\d+\\.\\d+", simplify = TRUE)))))

# De-duplicate any conditions, choosing the most recent version 
RCKMS_Version_dedup <- RCKMS_Version %>%
  group_by(Scheduled_Releases) %>%
  filter(RCKMS_Recent_Version == max(RCKMS_Recent_Version)) %>%
  distinct(Scheduled_Releases, .keep_all = TRUE) %>%
  ungroup()

# Create a table with variables "Scheduled Releases" and "Most Recent Version"
RCKMS_Version_selected <- RCKMS_Version_dedup %>%
  select(Scheduled_Releases, RCKMS_Recent_Version)


##################################################################

# Join tables to compare WA STATE RCKMS to RCKMS Most Recent Version
                       
# First, clean the "Condition Name" column in both tables
RCKMS_Version_selected_clean <- RCKMS_Version_selected %>%
  mutate(Scheduled_Releases = trimws(tolower(Scheduled_Releases)))  # Convert to lowercase and remove leading/trailing whitespace

rckms_WA_State_clean <- rckms_WA_State %>%
  mutate(Condition_Name = trimws(tolower(Condition_Name)))  # Convert to lowercase and remove leading/trailing whitespace

# Second, clean and normalize the strings in both tables
RCKMS_Version_selected_clean2 <- RCKMS_Version_selected_clean %>%
  mutate(Condition_Name = gsub("&nbsp;", " ", Scheduled_Releases)) %>%
  mutate(Condition_Name = tolower(trimws(Scheduled_Releases)))

rckms_WA_State_clean2 <- rckms_WA_State_clean %>%
  mutate(Condition_Name = gsub("&nbsp;", " ", Condition_Name)) %>%
  mutate(Condition_Name = tolower(trimws(Condition_Name)))


# Replace "&nbsp;" with a space in RCKMS_Version_selected_clean2
RCKMS_Version_selected_clean2 <- RCKMS_Version_selected_clean2 %>%
  mutate(Condition_Name = str_replace_all(Condition_Name, "&nbsp;", " "))


# Merge Step 1 and Step 2. 
merged_df <- left_join(rckms_WA_State_clean2,RCKMS_Version_selected_clean2, by = "Condition_Name")


data <- merged_df %>%
   select(Condition_Name, Status, RCKMS_dt, RCKMS_Recent_Version, 
          Version_WA)

#Check Dataset, there may not be ones that match on Condition Name due to HTML discrepancies. 
data$RCKMS_Recent_Version[str_detect(data$Condition_Name, "tickborne relapsing fever[[:space:]]*\\(tbrf\\)")] <- "2"


# Export data to CSV
write.csv(data, file = "C:/Users/MAP0303/Downloads/RCKMS Version Analysis.csv", row.names = FALSE)


# Q: How many that are not up to date with most recent RCKMS version?
instances_less_than <- sum(data$Version_WA < data$RCKMS_Recent_Version, na.rm = TRUE)
# Print the count
print(instances_less_than)
# Answer: N = 34

filtered_data <- data[data$Version_WA < data$RCKMS_Recent_Version & !is.na(data$Version_WA) & !is.na(data$RCKMS_Recent_Version), ]
# Export data to CSV
write.csv(filtered_data, file = "C:/Users/MAP0303/Downloads/RCKMS Needs Updates.csv", row.names = FALSE)



# What conditions are NA?
conditions_na <- data %>%
  filter(is.na(Version_WA) | is.na(RCKMS_Recent_Version)) %>%
  pull(Condition_Name)

# Print the list of conditions with NA values in WA_RCKMS_Version or Most_Recent_Version
print(conditions_na)




# END OF CODE # 