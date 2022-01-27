#!/usr/bin/env Rscript
# Read vfld data and save it in sqlite format
# This version of the function is the same as for deterministic
# but with a few more options for ensembles
library(harp)
library(argparse)

parser <- ArgumentParser()


parser$add_argument("-final_date", type="character", 
    default="None",
    help="First date to process [default %(default)s]",
    metavar="String")

parser$add_argument("-start_date", type="character", 
    default="None",
    help="Last date to process [default %(default)s]",
    metavar="String")

parser$add_argument("-vfld_path", type="character", 
     default="/scratch/ms/dk/nhd/vfld_sample/",
    help="Path for vfld data [default %(default)s]",
    metavar="String")

parser$add_argument("-vfld_sql", type="character", 
     default="/scratch/ms/ie/duuw/vfld_vobs_sample/FCTABLE",
    help="Path to store sqlite files [default %(default)s]",
    metavar="String")

parser$add_argument("-models", type="character", 
     default="vflddatatrunk_r17057_update,vflddata43h22tg3,vflddataWFP_43h22tg3",
    help="Model [default %(default)s]",
    metavar="String")

parser$add_argument("-fclen", type="integer", 
     default=24,
    help="Forecast length [default %(default)s]",
    metavar="Integer")

parser$add_argument("-file_temp", type="character", 
     default="vfld",
    help="file template for vfld files [default %(default)s]",
    metavar="String")

args <- parser$parse_args()

vfld_path <- args$vfld_path
vfld_sql_path <- args$vfld_sql
                 
#fcst_model <- c("vflddatatrunk_r17057_update","vflddata43h22tg3","vflddataWFP_43h22tg3")


models <- strsplit(args$models,",")
fcst_models <-c()
for (i in 1:lengths(models)) {
        fcst_models <- append(fcst_models, models[[1]][i])
}

first_fcst <-args$start_date
last_fcst <- args$final_date
fclen <- args$fclen

#file_template <- args$file_temp
#defininig here some particular templates used by KNMI
#unfortunately this has to match the length of the other variable for fcst_models!
#Not sure how to pass this as input though...
file_template <- list(
                      vflddatatrunk_r17057_update = "{fcst_model}/vfldtrunk_r17057_updatembr000{YYYY}{MM}{DD}{HH}{LDT2}",
                      vflddata43h22tg3 = "{fcst_model}/vfld43h22tg3{YYYY}{MM}{DD}{HH}{LDT2}",
                      vflddataWFP_43h22tg3 = "{fcst_model}/vfldWFP_43h22tg3{YYYY}{MM}{DD}{HH}{LDT2}"
                      )
                      

surface_params  <- c("Pmsl","RH2m","S10m","T2m") #,"AccPcp12h","AccPcp24h") #Params to extract
#allparams  <- c("AccPcp0h","AccPcp") #Params to extract
vertical_params <- c("T","RH","S","D","Q")

#using this example as 

cat("<<<<<< PROCESSING SURFACE PARAMETERS for ",fcst_models, ">>>>>>>\n")
for (param in surface_params)
{
    cat("Saving ",param,"\n")
    read_forecast(
      start_date    = first_fcst,
      end_date      = last_fcst,
      fcst_model     = fcst_models,
      parameter = param,
      lead_time = seq(0,fclen,1),
      file_path = vfld_path,
      file_template = file_template, #"vfld",
      output_file_opts =  sqlite_opts(path =  vfld_sql_path),
      return_data = TRUE
    )

}

cat("<<<<<< PROCESSING UPPER AIR PARAMETERS for ",fcst_models, ">>>>>>>\n")
for (param in vertical_params)
{
    cat("Saving ",param,"\n")
    read_forecast(
      start_date    = first_fcst,
      end_date      = last_fcst,
      file_format = file_template, #"vfld",
      fcst_model     = fcst_models,
      parameter = param,
      lead_time = seq(0,fclen,1),
      file_path = vfld_path,
      file_template = file_template, #"vfld",
      output_file_opts =  sqlite_opts(path =  vfld_sql_path),
      return_data = TRUE
    )

}

#Write the last date processed
#cat(last_fcst,file="lastdate.txt",sep="\n")
