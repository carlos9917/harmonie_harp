#!/usr/bin/env Rscript

#Calculate bias and stde (add other scores as needed)
# Plots them on a map
# 
library(harp)

library(argparse)
parser <- ArgumentParser()

parser$add_argument("-domain", type="character",
    default="None",
    help="Domain to select [default %(default)s]",
    metavar="Domain to select, based on station list")

#List of stations. SEPARATED by COMMA
parser$add_argument("-SID_range", type="character",
    default="6000,6199",
    help="Station range to select [default %(default)s]",
    metavar="The station IDs to select (range")

parser$add_argument("-start_date", type="character",
    default="None",
    help="First date to process [default %(default)s]",
    metavar="Date in format YYYYMMDDHH")

parser$add_argument("-final_date", type="character",
    default="None",
    help="Final date to process [default %(default)s]",
    metavar="Date in format YYYYMMDDHH")

#List of models. SEPARATED by COMMA
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

parser$add_argument("-min_num_obs", type="integer",
                    default=30,
                    help="Minimum number of observations  to consider for the scores calculation [default %(default)s]",
                    metavar="Integer")

parser$add_argument("-score", type="character",
                    default="bias",
                    help="Score to plot [default %(default)s]",
                    metavar="String")


args <- parser$parse_args()

fcst_sql_path <- args$sql_path_forecast
vobs_sql_path <- args$sql_path_observation
end_date <- args$final_date
start_date <- args$start_date
save_rds <- args$save_rds
models <- strsplit(args$models,",")
min_num_obs <- args$min_num_obs
score <- args$score

models_to_compare <-c()
for (i in 1:lengths(models)) {
    models_to_compare <- append(models_to_compare, models[[1]][i])
}
cat("Models to compare ",models_to_compare,"\n")

cat("Plotting scores period ",start_date,"-",end_date,"\n")

#pngfile <- paste("map",as.character(start_date),as.character(end_date),"std.png",sep="_")

pooled_by <- "SID"
domain <- args$domain

selected_stations <- NULL


if ( domain != "None") { 
     source("select_stations.R")
     sql_file <- "/scratch/ms/ie/duuw/vfld_vobs_sample/OBSTABLE/OBSTABLE_2021.sqlite"
    #NOTE: available domains is defined in select_stations.R
    #Selection based on domain and pre-selected list
    if (is.element(domain,available_domains))
    {
     cat("Selecting stations from domain ",domain," \n")
     selected_stations <- pre_sel_lists(domain,sql_file)
    }
    else
    {
        cat(domain," not in available domain list for domain selection!\n")
        cat("Available domains ",available_domains,"\n")   
        quit(1)
    }
}

parameters <- c("T2m", "S10m", "RH2m", "Pmsl") #,"AccPcp12h","AccPcp24h")
by_step <- "12h"

for (param in parameters) {
    cat("Read forecast for ",param,"\n")
    fcst <- read_point_forecast(
      start_date = start_date,
      end_date   = end_date,
      stations = selected_stations,
      fcst_model = models_to_compare,
      fcst_type  = "det",
      parameter  = param,
      by         = by_step,
      file_path  = fcst_sql_path
    )
    # make sure only considering forecasts for same time and location
    fcst <- common_cases(fcst)
    
    cat("Read observations for ",param,"\n")
    obs <- read_point_obs(
        start_date = first_validdate(fcst),
        end_date   = last_validdate(fcst),
        parameter  = param,
        obs_path   = vobs_sql_path,
        stations = selected_stations
                             )
#This one includes some units transformations, as suggested by Isabel
if ({{param}} == "T2m" ){
    print("Converting T2m forecasts and observations to Celsius\n")
     fcst_obs <- join_to_fcst(
             scale_point_forecast(fcst, -273.15, "degC"),
             scale_point_obs(obs, T2m, -273.15, "degC")
                        )
            }
 
else if ({{param}} == "Q2m" || {{param}} == "Q1000" || {{param}} == "Q850" || {{param}} == "Q700" ){
     print("Converting Q forecasts and observations to g/kg \n")
     fcst_obs <- join_to_fcst(
          scale_point_forecast(fcst, 1000, "g/Kg", multiplicative = TRUE),
          scale_point_obs(obs, {{param}}, 1000, "g/Kg", multiplicative = TRUE)
                         )
        }
else {
    print("No unit conversion \n")
   fcst_obs <- fcst %>% join_to_fcst(obs)
    }

   #following same naming as James' example
   verif_tdf_sid <- det_verify(
            fcst_obs,
            param,
            show_progress = FALSE,
            groupings = c("SID")
        )
   #filter the cases in which  there were not enough observations
   #verif_tdf_sid <- filter_list(verif_tdf_sid, num_cases > min_num_obs)
   #print(fcst_obs[["cca_dini25a_l90_arome"]])
   source("maps_utils.R")
   #map_df <- set_map_df(verif_tdf_sid,models,fcst)
   #map_df,min_lat,max_lat,min_lon,max_lon,par_unit <- set_map_df(verif_tdf_sid,models,fcst)
   map_input <- set_map_df(verif_tdf_sid,models,fcst_obs[["cca_dini25a_l90_arome"]])
   map_df <- map_input[1]$det_summary_scores
   min_lat <- map_input[3][[1]]
   max_lat <- map_input[4][[1]]
   min_lon <- map_input[5][[1]]
   max_lon <- map_input[6][[1]]
   par_unit <- map_input[7][[1]]
   #print(map_df)
   #cat(min_lat)
   #cat(min_lon)
   #cat(max_lat)
   #cat(max_lon)
   #cat(par_unit)
   #par_unit <- "C"
   ptype <- "det"
   fig_width <- 10
   fig_height <- 7
   png_archive <- "/home/ms/dk/nhd/R/harmonie_harp/scr"
   subtitle_str <- "test"#not used at the moment
   stat_choice <- score
   title_str <- paste0(score," for all stations in DINI domain")
   map_df <- as.data.frame(map_df)

   surfacemap(map_df,
              param,
              stat_choice,
              par_unit,
              ptype,
              title_str,
              subtitle_str,
              pname_str,
              min_lon,
              max_lon,
              min_lat,
              max_lat,
              png_archive,
              fig_width,
              fig_height)
    #pngfile <- paste(paste("map",param,start_date,end_date,sep="_"),".png",sep="")

    #ggsave(the_map,filename=pngfile,width=fig_width,height=fig_height)
}
