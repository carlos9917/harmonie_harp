# Read and save data in sqlite format
# Do vobs first, followed by vfld for model in testing, EC9 for reference

library(harp)
vobs_path <- "/scratch/ms/ie/duuw/vfld_vobs_sample/vobs"
vobs_sql_path   <- "/scratch/ms/ie/duuw/vfld_vobs_sample/OBSTABLE"
#Just to test them separately
SAVE_VOBS <- FALSE
SAVE_VFLD_DINI <- FALSE
SAVE_VFLD_EC9 <- TRUE


first_fcst <- 2021090700

#Check all vobs files to decide last date
all_files <- list.files("/scratch/ms/ie/duuw/vfld_vobs_sample/vobs")
#collecting here the last date from the vobs file.
last_fcst <- as.integer(substring(all_files[length(all_files)],5,))
cat("Collecting from ",first_fcst," to ",last_fcst)

print("Reading and saving obs data")
obs_data <- read_obs_convert(
  start_date  = first_fcst,
  end_date    = last_fcst,
  obs_path    = vobs_path,
  sqlite_path = vobs_sql_path
  )

vfld_sql_path   <- "/scratch/ms/ie/duuw/vfld_vobs_sample/FCTABLE"

#Path for new model in testin:

fcst_model <- "cca_dini25a_l90_arome"
vfld_path <- "/scratch/ms/ie/duuw/vfld_vobs_sample/vfld"

allparams  <- c("Pmsl","RH2m","S10m","T2m","AccPcp12h","AccPcp24h") #Params to extract



#this didnt work for vfld files. R is shit to detect digits in string.
#model_path <- file.path(vfld_path,fcst_model)
#all_files <- list.files(model_path)
#last_fcst <- as.integer(substring(all_files[length(all_files)],5,))
#cat("Collecting from ",first_fcst," to ",last_fcst)

# NOTE: Collecting forecast times 0 to 3, since this seem to be
# the length of the dini model in testing

cat("Processing ",fcst_model)
for (param in allparams)
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


#EC9
vfld_path <- "/scratch/ms/dk/nhz/oprint"
fcst_model <- "EC9"
cat("Processing ",fcst_model)

for (param in allparams)
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
