# Harmonie_harp
harp scripts for plotting score cards for the Early Common DINI Suite (ECDS)

## scr
R scripts to call harp and plot score cards
These are simply some scripts that call basic harp functions
to plot score cards, standard scores like bias and rmse and also to plot
vertical profiles.
They include command line arguments to define start and final date, etc


- read_save_vobs.R: save the vobs data to sqlite format
- read_save_vfld.R: save the vfld data to sqlite format
- standard_scores.R: plot bias and stde on the same plot. A station list or domain can be selected.
- create_scorecards.R: create score card (ref model is EC9)
- vertical_profiles.R: create vertical profiles
- select_stations.R: list of stations and polygons defining a particular domain (used to select stations). Taken from the monitor verification package.
- find_last_date.R: some helper functions
- check_last_dtg.R: a crude script to check last date available

There is also a few bash scripts used as wrappers for the above scripts.

## transfer
These scripts are used to copy over data from ecgate
to the local hpc at DMI and then to the hirlam server.
They also generate and update a very crude set of html
files that can be displayed in the [hirlam server](https://hirlam.org/portal/uwc_west_validation/index.html)
(requires HIRLAM credentials).

Models used up to now:
cca_dini25a_l90_arome
EC9

### STILL TO DO:
