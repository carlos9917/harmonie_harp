#!/usr/bin/env Rscript
# Read vobs data and save it in sqlite format

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

parser$add_argument("-vobs_path", type="character",
     default="/scratch/ms/dk/nhd/vfld_sample/vobs",
    help="Path for vfld data [default %(default)s]",
    metavar="String")

parser$add_argument("-vobs_sql", type="character",
     default="/scratch/ms/ie/duuw/vfld_vobs_sample/OBSTABLE",
    help="Path to store sqlite files [default %(default)s]",
    metavar="String")

args <- parser$parse_args()


vobs_path <- args$vobs_path
vobs_sql_path <- args$vobs_sql
first_fcst <- args$start_date
last_fcst <- args$final_date
#vobs_path <- "/scratch/ms/ie/duuw/vfld_vobs_sample/vobs"
#vobs_sql_path   <- "/scratch/ms/ie/duuw/vfld_vobs_sample/OBSTABLE"
#first_fcst <- 2021090700
#last_fcst <-  2021100100

cat("Collecting vobs data  from ",first_fcst," to ",last_fcst)

#print("Reading and saving obs data")
obs_data <- read_obs_convert(
  start_date  = first_fcst,
  end_date    = last_fcst,
  obs_path    = vobs_path,
  sqlite_path = vobs_sql_path
  )


