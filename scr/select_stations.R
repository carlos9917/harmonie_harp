library(RSQLite)

#Only these domains have been hard-coded below for SYNOP stations!
available_domains <- c("DK","DKland","DKcoast","Greenland","IE_EN","NL","IS")

#This one returns only the corners of selected domains
#Currently being used to select TEMP stations 
dom_corners <- function(domain)
     {
         avail_corners <- c("IE_EN","IS","NL")
     if (!(is.element(domain,avail_corners))) {
         cat("Domain ",domain, " not in corner list:\n")
         cat(avail_corners,"\n")
         cat("Stopping here \n")
         quit("no")
     }

     if (domain == "IE_EN")  #IrelandEngland bounding box
         {
         slat <- 50.0
         wlon <- -11.0
         nlat <- 60.0
         elon <- 2.0
         corner_list <- list(slat=slat,wlon=wlon,nlat=nlat,elon=elon)
         return (corner_list)
         }
     if (domain == "IS") #Iceland bounding box
         {
         slat <- 62.0
         wlon <- -25.0
         nlat <- 67.0
         elon <- -12.0 
         corner_list <- list(slat=slat,wlon=wlon,nlat=nlat,elon=elon)
         return (corner_list)
         }
     if (domain == "NL") #Netherlands bounding box
     {
         slat <- 51.0
         wlon <- 1.5
         nlat <- 54.5
         elon <- 9.0
         corner_list <- list(slat=slat,wlon=wlon,nlat=nlat,elon=elon)
         return(corner_list)

     }
     #This box is too big, end hitting Swedish and German stations
     #if (domain == "DK") #Continental DK bounding box
     #{
     #     slat <- 54.0
     #     wlon <- 8.0
     #     nlat <- 58.0
     #     elon <- 13.0
     #    corner_list <- list(slat=slat,wlon=wlon,nlat=nlat,elon=elon)
     #    return(corner_list)
     #}

    }

#Some help functions to select stations for verification

# Select list of stations from a SQL file and return the list
# It expects sql_file to be an OBS file
select_stations <- function(SID_beg,SID_end,sql_file)
{

    #SID_beg <- 6000
    #SID_end <- 7000
    #sql_file <- "/scratch/ms/ie/duuw/vfld_vobs_sample/OBSTABLE/OBSTABLE_2021.sqlite"
    con <- dbConnect(drv=RSQLite::SQLite(), dbname=sql_file)
    #print the tables
    #tables <- dbListTables(con)
    #print(tables)
    
    #df <- dbGetQuery(conn=con, statement=paste("SELECT * FROM FC", sep=""))
    #For OBS
    df <- dbGetQuery(conn=con, statement=paste("SELECT * FROM SYNOP", sep=""))
    
    #Select only Denmark Stations
    stations <- as.array(df[df$SID >= SID_beg & df$SID <= SID_end ,]$SID)
    dbDisconnect(con)
    return(stations)

}

#Print TEMP stations SIDs in a forecast SQLite file, given a domain box
print_temp_stations <- function(sql_file,domain)
{
    #con <- dbConnect(drv=RSQLite::SQLite(), dbname=sql_file)
    #tables <- dbListTables(con)
    #print(tables)
    #df <- dbGetQuery(conn=con, statement=paste("SELECT * FROM FC", sep=""))
    #print(head(df))
    #print(unique(df$SID))
    corners <- dom_corners(domain)

    stnlist <- stations_domain_box(corners$slat, corners$wlon, corners$nlat, corners$elon,sql_file,"FC")


    #stnlist <- as.array(unique(df$SID))
    #dbDisconnect(con)
    return(stnlist)
}



#Function below returns station lists taken from monitor 
#Not all contain station lists, some are specified by a 
# bounding box. All data taken from one of monitor's Env_exp files
# sql_file should be an OBS file
pre_sel_lists <- function(domain,sql_file)
{
     if (domain == "IE_EN")  #IrelandEngland bounding box
         {
         slat <- 50.0
         wlon <- -11.0
         nlat <- 60.0
         elon <- 2.0
         stnlist <- stations_domain_box(slat, wlon, nlat, elon, sql_file,"SYNOP")
         return (stnlist)
         }

     if (domain == "IS") #Iceland bounding box
         {
         slat <- 62.0
         wlon <- -25.0
         nlat <- 67.0
         elon <- -12.0 
         stnlist <- stations_domain_box(slat, wlon, nlat, elon, sql_file,"SYNOP")
         return (stnlist)
         }
     if (domain == "NL") #Netherlands bounding box
     {
         slat <- 51.0
         wlon <- 1.5
         nlat <- 54.5
         elon <- 9.0
         stnlist <- stations_domain_box(slat, wlon, nlat, elon, sql_file,"SYNOP")
         return (stnlist)

     }
     #Some specific lists for Denmark
     if (domain == "DK") 
     {
         stnlist <- c(06030,06041,06043,06049,06052, 06058,06060,06070,06072,
                     06073,06074,06079,06080,06081,06096,06102,06104,06110,
                     06116,06118,06119,06120,06123,06126,06135,06138,06141,
                     06149,06151,06154,06156,06165,06168,06170,06180,06181,
                     06190,06193)
         return (stnlist)
     }
     if (domain == "DKland") 
     {
         stnlist <- c(06030,06049,06060,06072,06102,06104,06110,06116,
                     06120,06126,06135,06141, 06156,06170)
                     
         return (stnlist)
     }
     if (domain == "DKcoast") 
     {
         stnlist <- c(06041,06043,06052,06058,06073,
                      06079,06081,06096,06119,06123,06126,06138,
                      06149,06151,06165,06193)
                     
         return (stnlist)
     }
     if (domain == "Greenland") 
     {
         stnlist <- c(4208,4214,4220,4242,4250,4253,4260,4266,4272,4285,4320,4351,4373)
                     
         return (stnlist)
     }
}


# returns the stations based on the domain box
#Note it expects a synop sql file 
stations_domain_box <- function(slat, wlon, nlat, elon, sql_file, table)
{
    con <- dbConnect(drv=RSQLite::SQLite(), dbname=sql_file)
    #df <- dbGetQuery(conn=con, statement=paste(paste("SELECT * FROM SYNOP", sep=""))
    df <- dbGetQuery(conn=con, statement=paste("SELECT * FROM ",table, sep=""))
    stations <- as.array(df[df$lat >= slat & df$lat <= nlat & df$lon >= wlon &  df$lon <= elon,]$SID)
    #Just for checking output:
    #lats <- as.array(df[df$lat >= slat & df$lat <= nlat & df$lon >= wlon &  df$lon <= elon,]$lat)
    #lons <- as.array(df[df$lat >= slat & df$lat <= nlat & df$lon >= wlon &  df$lon <= elon,]$lon)
    #print(unique(lats))
    #print(unique(lons))
    #print(unique(stations))
    dbDisconnect(con)
    return(as.array(unique(stations)))
}
