#' Extract Taiwan Air Quality Data
#' Author: Jianzhao Bi
#' Date: 9/21/2019

library(xml2)
library(rvest)
library(data.table)

# Site name and HTML
site.df <- data.frame(Name = c('North', 'ChuMiao', 'Central', 'YunChiaNan', 'KaoPing', 'Yilan', 'HuaTung', 'Island'),
                      HTML = c('https://taqm.epa.gov.tw/pm25/en/PM25A.aspx?area=1',
                               'https://taqm.epa.gov.tw/pm25/en/PM25A.aspx?area=3',
                               'https://taqm.epa.gov.tw/pm25/en/PM25A.aspx?area=4',
                               'https://taqm.epa.gov.tw/pm25/en/PM25A.aspx?area=6',
                               'https://taqm.epa.gov.tw/pm25/en/PM25A.aspx?area=7',
                               'https://taqm.epa.gov.tw/pm25/en/PM25A.aspx?area=8',
                               'https://taqm.epa.gov.tw/pm25/en/PM25A.aspx?area=9',
                               'https://taqm.epa.gov.tw/pm25/en/PM25A.aspx?area=0'))

for (i in 1 : nrow(site.df)) {
  
  # --- Get the TW Air Quality data table --- #
  doc.html <- read_html(as.character(site.df$HTML[i]))
  # Get the AQ table
  new.html <- xml_find_all(doc.html, xpath = '///table[@class=\'TABLE_G\']') 
  new.df <- html_table(new.html[[1]])
  names(new.df) <- c('Name', 'Current_PM25', 'PreviousHour_PM25', 'Chart')
  # Get the AQ time
  new.time.html <- xml_find_all(doc.html, xpath = '///span[@id=\'ctl07_labText1\']')
  new.time <- xml_text(new.time.html)
  new.time <- unlist(strsplit(x = new.time, split = 'Published:'))[2]
  new.df$DateTime <- new.time
  # Subset the data frame
  new.df <- new.df[, c("DateTime", "Name", "Current_PM25", "PreviousHour_PM25")]
  
  # --- Update the existing AQ data --- #
  old.file <- paste0('/home/jbi6/envi/TWAQIData/data/Taiwan_', site.df$Name[i], '.csv') 
  
  if (file.exists(old.file)) {
    # Load existing table
    old.df <- fread(file = old.file)
    # Find and combine the data that do not exist in the old table
    idx <- !(new.df$DateTime %in% old.df$DateTime)
    add.df <- new.df[idx, ]
    old.df <- rbindlist(list(old.df, add.df))
  } else {
    old.df <- new.df
  }
  # Reorder
  old.df <- old.df[order(old.df$DateTime, decreasing = T), ] 
  
  # --- Write the updated table --- #
  write.csv(old.df, file = old.file, row.names = F)
  
}




