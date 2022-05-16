#!/usr/bin/env Rscript

#Calculate bias and stde (add other scores as needed)
# Plots them in two panels, one on top of each other
# 
# Select stations if want to limit verification to a particular
# region 
# According to this: https://library.wmo.int/doc_num.php?explnum_id=5730
# (Manual on Codes - Regional Codes and National Coding Practices, Vol II)
# Denmark 06000 - 06199
# Ireland 950 - 999
# Netherlands: 200 - 399
# Iceland 04000 - 04199
library(harp)
library(cowplot)

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

parser$add_argument("-rds_path", type="character",
    default="/scratch/ms/ie/duuw/vfld_vobs_sample/verif_scores/std_scores",
    help="Path for saving the rds files [default %(default)s]",
    metavar="Verification data")

#NOTE: store_false sets this to TRUE if the argument is NOT called, otherwise to FALSE if it is called
# Hence it is FALSE by default
parser$add_argument("-save_rds", action="store_true",
                help="Save rds file for verification or not [default %(default)s]")

# FALSE by default
parser$add_argument("-skip_png", action="store_true",
                help="Export png files. False by default [default %(default)s]")

parser$add_argument("-min_num_obs", type="integer",
                    default=30,
                    help="Minimum number of observations  to consider for the scores calculation [default %(default)s]",
                    metavar="Integer")


#some helper functions to find last avail date
source("find_last_date.R")
#some helper functions here, as well as a list of stations to exclude
source("select_stations.R")
args <- parser$parse_args()

fcst_sql_path <- args$sql_path_forecast
vobs_sql_path <- args$sql_path_observation
end_date <- args$final_date
start_date <- args$start_date
save_rds <- args$save_rds
models <- strsplit(args$models,",")
min_num_obs <- args$min_num_obs
models_to_compare <-c()
for (i in 1:lengths(models)) {
    models_to_compare <- append(models_to_compare, models[[1]][i])
}
cat("Models to compare ",models_to_compare,"\n")
#Path with the sqlite data
#fcst_sql_path        <- "/scratch/ms/ie/duuw/vfld_vobs_sample/FCTABLE"
#vobs_sql_path        <- "/scratch/ms/ie/duuw/vfld_vobs_sample/OBSTABLE"
#start_date <- 2021090700
#fcst_model <- "cca_dini25a_l90_arome"
#ref_model <- "EC9"
#models_to_compare <- c(ref_model, fcst_model)

# If no end_date given, take it from last available date
if (end_date == "None")
{
    print("Selecting last date from last available date in sql files")
    #Select month and year from first date,
    month <- substring(as.character(start_date),5,6)
    year <- substring(as.character(start_date),1,4)
    #Look for last date available in files. Use forecast model
    end_date <- find_last_date(file.path(fcst_sql_path,fcst_model,year,month))
}
cat("Plotting scores period ",start_date,"-",end_date,"\n")

pngfile <- paste("scores",as.character(start_date),as.character(end_date),"std.png",sep="_")

pooled_by <- "SID"
domain <- args$domain

selected_stations <- NULL

#models_to_compare <- c(ref_model, fcst_model)

if ( domain != "None") { 
     sql_file <- "/scratch/ms/ie/duuw/vfld_vobs_sample/OBSTABLE/OBSTABLE_2021.sqlite"
     #Old alternative method: select by station range
     #SID_beg <- strsplit(args$SID_range,",")[[1]][1]
     #SID_end <- strsplit(args$SID_range,",")[[1]][2]
     #source("select_stations.R")
     #cat("Selecting stations in range [",SID_beg,",",SID_end,"] \n")
     #selected_stations <- select_stations(SID_beg,SID_end,sql_file)

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
        quit("yes")
    }
}

parameters <- c("S10m","T2m", "RH2m", "Pmsl") #,"AccPcp12h","AccPcp24h")
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
    if (length(models_to_compare) > 1) {
    fcst <- common_cases(fcst)
    }
    else {
        cat("Not doing the common_cases, since only one model: ",args$models)
    }
    #filter bad stations. Just for testing, avoid including bad stations in map plots later
    #cat("Filtering out stations ",really_bad_stations,"\n")
    #fcst <- fcst %>% filter_list(!SID %in% really_bad_stations)
    
    cat("Read observations for ",param,"\n")
    obs <- read_point_obs(
        start_date = first_validdate(fcst),
        end_date   = last_validdate(fcst),
        parameter  = param,
        obs_path   = vobs_sql_path,
        stations = selected_stations
                             )
#Original version    
#   fcst_obs <- fcst %>%
#    join_to_fcst(obs)

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




   verif <- det_verify(
        fcst_obs,
        param,
              show_progress = FALSE,
           groupings = list("leadtime",c("leadtime", "fcst_cycle"))
        )

### Test: check if something is too wrong

   #check_fc <- bind_fcst(fcst_obs) # this creates a dataframe
   #check_fc <- mutate(check_fc,bias=forecast-S10m) #cal the bias
  #if ({{param}} == "S10m") {
  #   get_terrible_bias <- filter_list(verif, abs(verif$det_summary_scores$bias) > 0.4)
  #   print("bad bias")
  #   print(get_terrible_bias)
  #   #order_bias  <- arrange(verif$det_summary_scores, bias)
  #   print("original")
  #   print(verif) #$det_summary_scores)
  #   #print(verif["cca_dini25a_l90_arome"]$det_summary_scores)
  #   stations_extreme_bias <- unique(get_terrible_bias$SID)
  #   print("Checking stations with awful bias for wind speed")
  #   print(stations_extreme_bias)
  #   quit("no")
  #}


   #filter the cases in which  there were not enough observations
   cat("--------------------------------------------\n")
   cat("Number of cases before filtering ",length(verif$det_summary_scores$num_cases),"\n")
   verif <- filter_list(verif, num_cases > min_num_obs)
   print("Number of cases remaining after filtering ")
   #No idea why it does not print as before, complains of "invalid printing digits". Printing it separately
   print(length(verif$det_summary_scores$num_cases))
   cat("--------------------------------------------\n")
   
   #Save the verif data. Naming of rds setup automatically by harp
   if (domain == "None" || save_rds) {

       #test here if I can do the summarizing and save separately?
       #library(dplyr)
       #verif_filter_rds <- verif
       #verif_filter_rds$det_summary_scores <- verif_filter_rds$det_summary_scores %>%
       #        filter(fcst_cycle %in% c("00", "06", "12", "18")) %>%
       #         group_by(leadtime) %>%
       #         summarize(meanbias= mean(bias),meanstd=mean(stde),mname=mname,num_cases=num_cases)
       #cat("Doing summarizing of data based on all cycles\n")
       #cat("--------------------------------------------\n")
       #cat(verif_filter_rds)
       #cat("--------------------------------------------\n")

       # I will be using a different grouping for the rds output
       verif_save <- det_verify(fcst_obs, 
                                param, 
                                show_progress = FALSE)
                                #20220507 turning this grouping off
                                #groupings = c("leadtime", "SID", "lat", "lon"))
       #The following snippet is to filter the SIDs of really bad stations
       #get_terrible_bias <- filter_list(verif_save, abs(verif_save$det_summary_scores$bias) > 10)
       #avoid_these <- unique(get_terrible_bias$det_summary_scores$SID)
       #print("Bad stations")
       #print(avoid_these)
       #quit("no")
       ###########################################################
       #do the same filtering here
       print("Filtering rds output for a min number of stations")
       verif_save <- filter_list(verif_save, num_cases > min_num_obs)
       cat("Saving scores for domain",domain," \n")
       save_point_verif(verif_save,args$rds_path)
   }    

  if (!args$skip_png) {
   bias <- plot_point_verif(verif, bias,plot_num_cases=FALSE,x_axis=leadtime,
                         facet_by = vars(fcst_cycle),
                         filter_by = vars(grepl(";", fcst_cycle)))

   stde <- plot_point_verif(verif, stde,plot_num_cases=FALSE,x_axis=leadtime,
                         facet_by = vars(fcst_cycle),
                        filter_by = vars(grepl(";", fcst_cycle)))
    bias_stde <- plot_grid(bias, stde, align='h', rel_widths=c(0.5,0.5), nrow = 2,
    labels=c('',''))

    pngfile <- paste(paste("bias","stde",param,start_date,end_date,sep="_"),".png",sep="")
    if (domain != "None"){
                   pngfile <- paste(paste("bias","stde",param,start_date,end_date,domain,sep="_"),".png",sep="")
                         }

    ggsave(pngfile)
  }
  else {
       print("Not exporting the png plots")
       }
}
