#Calculate bias and stde (add as needed)
library(harp)
library(cowplot)


#This is just a sample sql to select the list of stations based on domain
#Hard coded here for the moment
sample_sql_file <- "/scratch/ms/ie/duuw/vfld_vobs_sample/FCTABLE/cca_dini25a_l90_arome/2021/10/FCTABLE_T_202110_00.sqlite"

library(argparse)
parser <- ArgumentParser()

parser$add_argument("-station", type="character",
    default=NULL,
    help="Station(s) to plot [default %(default)s]",
    metavar="Temp station to plot")

parser$add_argument("-date", type="character",
    default="None",
    help="Date to process [default %(default)s]",
    metavar="Date in format YYYYMMDDHH")

parser$add_argument("-models", type="character",
    default="EC9,cca_dini25a_l90_arome",
    help="Comma separated values for models [default %(default)s]",
    metavar="Provide models to evaluate as a string with commas")

parser$add_argument("-sql_path_forecast", type="character",
    default="/scratch/ms/ie/duuw/vfld_vobs_sample/FCTABLE",
    help="Path for sqlite files from the forecast [default %(default)s]",
    metavar="Forecast data")

parser$add_argument("-sql_path_observation", type="character",
    default="/scratch/ms/ie/duuw/vfld_vobs_sample/OBSTABLE",
    help="Path for sqlite files with observations [default %(default)s]",
    metavar="Observation data")

parser$add_argument("-domain", type="character",
    default="DINI",
    help="Domain to plot [default %(default)s]",
    metavar="Available domains: DINI,NL,IE_EN,IS")

#Set CL arguments
source("find_last_date.R")
args <- parser$parse_args()
fcst_sql_path <- args$sql_path_forecast
vobs_sql_path <- args$sql_path_observation
date <- args$date
models <- strsplit(args$models,",")
models_to_compare <-c()
for (i in 1:lengths(models)) {
    models_to_compare <- append(models_to_compare, models[[1]][i])
}
domain <- args$domain


cat("Plotting vertical profile on",date,"\n")
pngfile <- paste("vert_prof_",as.character(date),".png",sep="")

pooled_by <- "SID"
#models_to_compare <- c(ref_model, fcst_model)

parameters <- c("T","RH","S") #,"D","Q")
#parameters <- c("RH") #,"D","Q")
# Listing from one of the sql files:
#1         p           0     hPa
#2         Z           0       m
#3         T           0       K
#4        RH           0 percent
#5         D           0 degrees
#6         S           0     m/s
#7         Q           0   kg/kg
#8        Td           0       K

by_step <- "12h"

source("select_stations.R")
selected_stations <- args$station #NULL
#Select stations from list provided
if (!is.null(args$station))  {
    cat("Selecting stations from provided list ",args$station,"\n")
    split_stations <- strsplit(args$station,",")
    selected_stations <-c()
     for (i in 1:lengths(split_stations)) {
    selected_stations <- append(selected_stations, as.integer(split_stations[[1]][i]))
    }
check_stations <-  stations_domain_box(54, 8, 58, 13,"/scratch/ms/ie/duuw/vfld_vobs_sample/OBSTABLE/OBSTABLE_2021.sqlite","TEMP")
print(check_stations)
}

#Select stations for a particular domain
if ((args$domain != "DINI") & (is.null(args$station))) {
    cat("Selecting stations from domain name ",args$domain,"\n")
selected_stations <- print_temp_stations(sample_sql_file,args$domain)
}

yyyy <-substr(date, 1, 4)
mm <- substr(date,5,6)
last_dates_available <-c()
for (model in models_to_compare) {
     last_date_fcst <-find_last_date(file.path(fcst_sql_path,model,yyyy,mm))
     cat("Last date from ",model,last_date_fcst,"\n")
     last_dates_available <- append(last_dates_available, last_date_fcst)
}
print(last_dates_available)
for (check_date in last_dates_available)
{
    this_date <-strtoi(check_date)
    if (this_date < strtoi(date))
        {
          cat("Date ",date," not available\n")
          cat("Last available date is ",check_date,"\n")
          quit("yes")
        }
    else
    {
          cat("Date ",date," is available\n")
    }
}


#stationID <- selected_stations[1] #3005 #Test!
for (param in parameters) {
    cat("Reading forecast for ",param,"\n")
    fcst <- read_point_forecast(
      start_date = date,
      end_date   = date,
      fcst_model = models_to_compare,
      fcst_type  = "det",
      stations = selected_stations,
      parameter  = param,
      by         = by_step,
      file_path  = fcst_sql_path,
      vertical_coordinate = "pressure"
    )
    
    print("Last obs from fcst")
    print(first_validdate(fcst))
    print(last_validdate(fcst))
    cat("Reading observations for ",param,"\n")
    obs <- read_point_obs(
        start_date = first_validdate(fcst),
        end_date   = last_validdate(fcst),
        parameter  = param,
        stations = selected_stations,
        obs_path   = vobs_sql_path,
        vertical_coordinate = "pressure"
                             )
   #combine both 
    #print("Observations")
    #print(obs)
    #print("Forecast")
    #print(fcst)
   fcst_obs <- fcst %>%
    join_to_fcst(obs)

   #print(expand_date(fcst, fcdate))
   
   verif <- det_verify(fcst_obs, param, groupings = c("leadtime", "p"))
   plot_profile_verif(verif, bias, facet_by = vars(leadtime))
   pngfile <- paste(paste("vprof_bias",as.character(date),param,domain,sep="_"),".png",sep="")
   ggsave(pngfile)

   #This plots individual stations. Turning it off for the moment
   # for (stationID in selected_stations)
   # {
   #   pngfile <- paste(paste("vprof",as.character(date),param,domain,stationID,sep="_"),".png",sep="")
 
   #   cat("Plotting vertical profile for station ",stationID,"\n")
   #    plot_vertical_profile(
   #      fcst, 
   #      SID       = stationID,
   #      fcdate    = date,
   #      lead_time = 24
   #                     )
   #    #Apparently not possible to plot obs?!
   #    #plot_vertical_profile(
   #    #    obs, 
   #    #    SID       = stationID,
   #    #                   )
   #     ggsave(pngfile)
   #}


   #print(expand_date(obs,validdate))
    #Not plotting this yet
     #plot_vertical_profile(
     #    obs, 
     #    SID       = StationID,
     #    fcdate    = date,
     #    lead_time = 24
     #                   )

}
