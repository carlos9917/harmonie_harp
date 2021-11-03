#!/usr/bin/env Rscript
# Read vfld data and save it in sqlite format
library(harp)
library(argparse)

parser <- ArgumentParser()


parser$add_argument("-final_date", type="character", 
    default="None",# default="2021090700",
    help="First date to process [default %(default)s]",
    metavar="String")

parser$add_argument("-start_date", type="character", 
    default="None",#default="2021093000",
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

parser$add_argument("-model", type="character", 
     default="EC9",
    help="Model [default %(default)s]",
    metavar="String")

args <- parser$parse_args()

vfld_path <- args$vfld_path
vfld_sql_path <- args$vfld_sql
fcst_model <- args$model
first_fcst <-args$start_date
last_fcst <- args$final_date

    #Path for DINI
    #vfld_sql_path   <- "/scratch/ms/ie/duuw/vfld_vobs_sample/FCTABLE"
    
    #Path for EC9
    #vfld_path <- "/scratch/ms/dk/nhd/vfld_sample/"
    #fcst_model <- "EC9" 
    #first_fcst <- 2021090700
    #last_fcst <-  2021100100
#print(typeof(first_fcst))
#print(last_fcst)

surface_params  <- c("Pmsl","RH2m","S10m","T2m") #,"AccPcp12h","AccPcp24h") #Params to extract
#allparams  <- c("AccPcp0h","AccPcp") #Params to extract
vertical_params <- c("T","RH","S","D","Q")

cat("<<<<<< PROCESSING SURFACE PARAMETERS for ",fcst_model, ">>>>>>>\n")
for (param in surface_params)
{
    cat("Saving ",param,"\n")
    read_forecast(
      start_date    = first_fcst,
      end_date      = last_fcst,
      fcst_model     = fcst_model,
      parameter = param,
      lead_time = seq(0,24,1),
      file_path = vfld_path,
      file_template = "vfld",
      output_file_opts =  sqlite_opts(path =  vfld_sql_path),
      return_data = TRUE
    )

}

cat("<<<<<< PROCESSING UPPER AIR PARAMETERS for ",fcst_model, ">>>>>>>\n")
for (param in vertical_params)
{
    cat("Saving ",param,"\n")
    read_forecast(
      start_date    = first_fcst,
      end_date      = last_fcst,
      fcst_model     = fcst_model,
      parameter = param,
      lead_time = seq(0,24,1),
      file_path = vfld_path,
      file_template = "vfld",
      output_file_opts =  sqlite_opts(path =  vfld_sql_path),
      return_data = TRUE
    )

}

#Write the last date processed
#cat(last_fcst,file="lastdate.txt",sep="\n")


#Now do it for dini
#fcst_model <- "cca_dini25a_l90_arome"
#cat("<<<<<< PROCESSING ",fcst_model, ">>>>>>>\n")
#vfld_path <- "/scratch/ms/ie/duuw/vfld_vobs_sample/vfld"
#for (param in allparams)
#{
#    cat("Saving ",param,"\n")
#    read_forecast(
#      start_date    = first_fcst,
#      end_date      = last_fcst,
#      fcst_model     = fcst_model,
#      parameter = param,
#      lead_time = seq(0,24,1),
#      file_path = vfld_path,
#      file_template = "vfld",
#      output_file_opts =  sqlite_opts(path =  vfld_sql_path),
#      return_data = TRUE
#    )
#
#}
