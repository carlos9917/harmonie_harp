#!/usr/bin/env Rscript
library(argparse)
parser <- ArgumentParser()

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


source("find_last_date.R")
args <- parser$parse_args()
fcst_sql_path <- args$sql_path_forecast
vobs_sql_path <- args$sql_path_observation
date <- args$date
yyyy <-substr(date, 1, 4)
mm <- substr(date,5,6)
models <- strsplit(args$models,",")
models_to_compare <-c()
for (i in 1:lengths(models)) {
        models_to_compare <- append(models_to_compare, models[[1]][i])
}

last_dates_available <- c()
compare_dates_models <- function(models_to_compare,fcst_sql_path,vobs_sql_path,date)
{

    for (model in models_to_compare) {
             last_date_vfld <-find_last_date(file.path(fcst_sql_path,model,yyyy,mm))
         cat("Last date from ",model,last_date_vfld,"\n")
              last_dates_available <- append(last_dates_available, last_date_vfld)
    }
     #Not checking vobs at the moment.
     #last_date_vobs <-find_last_date(vobs_sql_path)
     #last_dates_available <- append(last_dates_available, last_date_vobs)
    return((unique(last_dates_available) == 1))

}

compare_dates_models(models_to_compare,fcst_sql_path,vobs_sql_path,date)

#end_date <- find_last_date(file.path(fcst_sql_path,fcst_model,year,month))
#cat("Last date available for ",fcst_model,":",end_date,"\n")

#print_contents("/scratch/ms/ie/duuw/vfld_vobs_sample/OBSTABLE/OBSTABLE_2021.sqlite","TEMP_params")
