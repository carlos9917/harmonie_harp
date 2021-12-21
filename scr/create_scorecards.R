library(harp)

library(argparse)
parser <- ArgumentParser()


parser$add_argument("-start_date", type="character",
    default="None",# default="2021090700",
    help="First date to process [default %(default)s]",
    metavar="Date in format YYYYMMDDHH")

parser$add_argument("-final_date", type="character",
    default="None",
    help="Final date to process [default %(default)s]",
    metavar="Date in format YYYYMMDDHH")

parser$add_argument("-ref_model", type="character",
    default="EC9",
    help="Reference model [default %(default)s]",
    metavar="Reference model")

parser$add_argument("-fcst_model", type="character",
    default="cca_dini25a_l90_arome",
    help="Model to evaluate [default %(default)s]",
    metavar="Model to evaluate")

parser$add_argument("-sql_path_forecast", type="character",
    default="/scratch/ms/ie/duuw/vfld_vobs_sample/FCTABLE",
    help="Path for sqlite files from the forecast [default %(default)s]",
    metavar="Forecast data")

parser$add_argument("-sql_path_observation", type="character",
    default="/scratch/ms/ie/duuw/vfld_vobs_sample/OBSTABLE",
    help="Path for sqlite files with observations [default %(default)s]",
    metavar="Observation data")

parser$add_argument("-domain", type="character",
    default="None",
    help="Domain to analyze [default %(default)s]",
    metavar="Domain to analyze. It will select stations based on pre-selected list ")

source("find_last_date.R")

args <- parser$parse_args()
#cat("Parsing arguments: ",args,"\n")
#Path with the sqlite data
fcst_sql_path   <- args$sql_path_forecast #     <- "/scratch/ms/ie/duuw/vfld_vobs_sample/FCTABLE"
vobs_sql_path   <- args$sql_path_observation #     <- "/scratch/ms/ie/duuw/vfld_vobs_sample/OBSTABLE"
#start_date <- 2021090700 #now a command-line argument

#These don't change for the moment, 
fcst_model <- args$fcst_model #"cca_dini25a_l90_arome"
ref_model <- args$ref_model # "EC9"
end_date <- args$final_date
start_date <- args$start_date
domain <- args$domain

# If no end_date given, take it from last available date
if (end_date == "None") 
{
    #Select month and year from first date,
    month <- substring(as.character(start_date),5,6)
    year <- substring(as.character(start_date),1,4)
    #Look for last date available in filesa
    #Select last date from the forecast model
    end_date <- find_last_date(file.path(fcst_sql_path,fcst_model,year,month))
    cat("Plotting score cards for period ",start_date,"-",end_date,"\n")
    #end_date <- 2021091200
    #end_date <- 2021092718
}

pngfile <- paste(paste("scorecards",as.character(start_date),as.character(end_date),sep="_"),".png",sep="")
#Change title if doing it for a particular domain
if (domain != "None"){
    pngfile <- paste(paste("scorecards",domain,as.character(start_date),as.character(end_date),sep="_"),".png",sep="")
    }


pooled_by <- "SID"
models_to_compare <- c(ref_model, fcst_model)

parameters <- c("T2m", "S10m", "RH2m", "Pmsl") #,"AccPcp12h","AccPcp24h")
by_step <- "12h"

#Select stations

selected_stations <- NULL #default

if ( domain != "None") {

    sql_file <- "/scratch/ms/ie/duuw/vfld_vobs_sample/OBSTABLE/OBSTABLE_2021.sqlite"
    source("select_stations.R")

    #Selection based on domain and pre-selected list (list of available domains defined in select_stations.R)
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



#Function to do the whole calculation
source("scorecard_function.R")


# Calculation starts here

scorecard_data <- lapply(
  parameters,
  scorecard_function,
  start_date = start_date,
  end_date   = end_date,
  by         = by_step,
  fcst_model = models_to_compare,
  fcst_type  = "det",
  fcst_path  = fcst_sql_path,
  obs_path   = vobs_sql_path,
  n          = 100,
  pooled_by  = "SID",
  stations   = selected_stations,
  min_cases  = 5
)


# The old version with pooled_bootstrap_score
#DO NOT USE, it is buggy
#scorecard_data <- bind_bootstrap_score(scorecard_data)

#This one uses the new bootstrap_verify function
scorecard_data <- bind_point_verif(scorecard_data)

#Save the verif data. Will this work here???
save_point_verif(scorecard_data,"/scratch/ms/ie/duuw/vfld_vobs_sample/verif_scores")


now <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
figtitle <-ggtitle(paste("DINI domain. Last update: ",now))
if (domain != "None"){
figtitle <-ggtitle(paste(domain," domain. Last update: ",now))
    }

plot <- plot_scorecard(
  scorecard_data,
  fcst_model = fcst_model,
  ref_model  = ref_model,
  scores     = c("rmse", "stde", "bias")
) + theme(legend.text = element_text(size = 6)) + ggtitle(figtitle)

ggsave(pngfile)

