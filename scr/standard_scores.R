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



source("find_last_date.R")
args <- parser$parse_args()

fcst_sql_path <- args$sql_path_forecast
vobs_sql_path <- args$sql_path_observation
end_date <- args$final_date
start_date <- args$start_date
models <- strsplit(args$models,",")
models_to_compare <-c()
for (i in 1:lengths(models)) {
    models_to_compare <- append(models_to_compare, models[[1]][i])
}

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
     source("select_stations.R")
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
    
    
    cat("Read observations for ",param,"\n")
    obs <- read_point_obs(
        start_date = first_validdate(fcst),
        end_date   = last_validdate(fcst),
        parameter  = param,
        obs_path   = vobs_sql_path,
        stations = selected_stations
                             )
   fcst_obs <- fcst %>%
    join_to_fcst(obs)

   verif <- det_verify(
        fcst_obs,
        param,
        #thresholds    = quantile(obs$S10m, c(0.25, 0.5, 0.75, 0.9, 0.95)),
              show_progress = FALSE,
           groupings = list("leadtime",c("leadtime", "fcst_cycle"))
        )
   #Save the verif data
   out_verif_file <-paste(paste("verif",param,start_date,end_date,sep="_"),".sqlite",sep="")
   save_point_verif(verif,"/scratch/ms/ie/duuw/vfld_vobs_sample/verif_scores")
   #save_point_verif(verif,file.path("/scratch/ms/ie/duuw/vfld_vobs_sample",out_verif_file))
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
