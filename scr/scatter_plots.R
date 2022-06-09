# Do the scatter plots
library(harp)
library(argparse)
library(patchwork) # this one to combine plots togethr below

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

#NOTE: store_false sets this to TRUE if the argument is NOT called, otherwise to FALSE if it is called
# Hence it is FALSE by default
parser$add_argument("-save_rds", action="store_true",
                help="Save rds file for verification or not [default %(default)s]")

parser$add_argument("-min_num_obs", type="integer",
                    default=30,
                    help="Minimum number of observations  to consider for the scores calculation [default %(default)s]",
                    metavar="Integer")



#this script is use sometimes to select last avail date
source("find_last_date.R")
#this script contains some station lists and help functions
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
    #filter bad stations. Turned off on 20220507
    # cat("Filtering out stations ",really_bad_stations,"\n")
    # fcst <- fcst %>% filter_list(!SID %in% really_bad_stations)

    
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

    #print(names(fcst_obs))
## function to combine all, from Andrew's tutorials
    plot_fun <- function(fcst_model, fcst_obs, param) {
        plot_scatter(fcst_obs, fcst_model, param) + labs(title = fcst_model) 
            }

    for (fcst_model in names(fcst_obs)) {
       cat("Doing scatter plot for ",fcst_model,"\n")
            if (fcst_model == names(fcst_obs)[1]) {
              my_plot <- plot_scatter(fcst_obs, {{fcst_model}}, {{param}}) + labs(title = {{fcst_model}})
  
            } else {
              my_plot <- my_plot + plot_scatter(fcst_obs, {{fcst_model}}, {{param}}) + labs(title = {{fcst_model}})
  
            }

    }

    #my_plot + plot_layout(nrow = 2, guides = "collect")
    pngfile = paste0(paste("scatterplot",param,start_date,end_date,sep="_"),".png")
    ggsave(filename=pngfile)

    #plot_scatter(fcst_obs,cca_dini25a_l90_arome,T2m)
    #for (model in models_to_compare)
    #{
    #  #print(model)
    #    plot_scatter(fcst_obs,{{model}},{{param}})
    #    pngfile = paste0(paste(model,"scat",param,start_date,end_date,sep="_"),".png")
    #    ggsave(filename=pngfile)
    #}

    #model <- "cca_dini25a_l90_arome"
    #         plot_scatter(fcst_obs,cca_dini25a_l90_arome,{{param}})
    #ggsave(the_map,filename=pngfile,width=fig_width,height=fig_height)
}
