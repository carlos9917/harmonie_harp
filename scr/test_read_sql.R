library(RSQLite)
library(argparse)
ifile <-
"/scratch/ms/ie/duuw/vfld_vobs_sample/FCTABLE/EC9/2021/09/FCTABLE_T2m_202109_18.sqlite"
ifile <- "/scratch/ms/ie/duuw/vfld_vobs_sample/FCTABLE/cca_dini25a_l90_arome/2021/09/FCTABLE_T2m_202109_18.sqlite"
ifile <- "/scratch/ms/ie/duuw/vfld_vobs_sample/OBSTABLE/OBSTABLE_2021.sqlite"
con <- dbConnect(drv=RSQLite::SQLite(), dbname=ifile)

tables <- dbListTables(con)
print(tables)

#df <- dbGetQuery(conn=con, statement=paste("SELECT * FROM FC", sep=""))
#For OBS
df <- dbGetQuery(conn=con, statement=paste("SELECT * FROM SYNOP", sep=""))

#Select only Denmark Stations
test <- as.array(df[df$SID >= 6000 & df$SID <= 7000 ,]$SID)


#print(colnames(df))
#df["validdate"]
print(max(df["validdate"],na.rm=TRUE))
last_utime <- tail(df["validdate"],n=1)
print(last_utime[1,1])
library(lubridate)
real_date <- as.Date(as.POSIXct(last_utime[1,1], origin="1970-01-01"),format="%Y%m%d")
final_date <- as.character(real_date,format="%Y%m%d%H")
print(final_date)

#parser <- ArgumentParser()
#parser$add_argument("-final_date", type="character", default="1991-01-01", 
#    help="Number of random normals to generate [default %(default)s]",
#    metavar="number")
#args <- parser$parse_args()
#print(args)



