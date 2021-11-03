# Open the a file in the path where the forecast sql files are
# saved and select last available date to plot

library(RSQLite)
#Find last available date in FC data
find_last_date <- function(fcst_sql_path)
{
    all_files <- list.files(fcst_sql_path)
    #print(all_files)
    last_file <- file.path(fcst_sql_path,all_files[length(all_files)])
    cat("Using file ",last_file," to determine last available date\n")

    #ifile <- "/scratch/ms/ie/duuw/vfld_vobs_sample/FCTABLE/EC9/2021/09/FCTABLE_T2m_202109_18.sqlite"
    
   con <- dbConnect(drv=RSQLite::SQLite(), dbname=last_file)

    tables <- dbListTables(con)
    df <- dbGetQuery(conn=con, statement=paste("SELECT * FROM FC", sep=""))
    last_utime <- tail(df["validdate"],n=1)
    library(lubridate)
    real_date <- as.Date(as.POSIXct(last_utime[1,1], origin="1970-01-01"),format="%Y%m%d")
    final_date <- as.character(real_date,format="%Y%m%d%H")
    dbDisconnect(con)
    #print(final_date)
    return(as.integer(final_date))
}

print_contents <- function(sqlfile,tablename)
{
  con <- dbConnect(drv=RSQLite::SQLite(), dbname=sqlfile)
  tables <- dbListTables(con)
  df <- dbGetQuery(conn=con, statement=paste("SELECT * FROM ",tablename, sep="")) 
  #print(df$synop_params)
  print(df)
  dbDisconnect(con)
  #print(df$temp_params)
}

