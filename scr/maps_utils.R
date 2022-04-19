# Map plotting functions. Adapted from James' harp scripts
# example models   = c("p143h211winterEXP0","irl43h22tg3_winter") 

# Define the map dataframe to be plotted
# 
set_map_df <- function(verif,fcst)
{

    # Get the corresponding lat/lons in order to plot a map
    sid_toget <- verif$det_summary_scores$SID # Common to EPS and DET
    #print(fcst$lat)
    lat_sids <- NULL
    lon_sids <- NULL
    for (sid_i in sid_toget){
      lat_v <- unique(fcst$lat[fcst$SID == sid_i])
      lon_v <- unique(fcst$lon[fcst$SID == sid_i])
      lat_v = lat_v[1]
      lon_v = lon_v[1]
      lat_sids <- c(lat_sids,lat_v)
      lon_sids <- c(lon_sids,lon_v)
    
    }
    verif$det_summary_scores$lat <- lat_sids
    verif$det_summary_scores$lon <- lon_sids
    #Plotting part
    # Get max/min lat/lon for plotting
     min_lat = min(lat_sids) - 0.2
     max_lat = max(lat_sids) + 0.2
     min_lon = min(lon_sids) - 0.2
     max_lon = max(lon_sids) + 0.2

     # Get some useful info
     par_unit <- unique(fcst$units)
     num_stat <- attr(verif, "num_stations")
     sdate    <- attr(verif, "start_date")
     edate    <- attr(verif, "end_date")
     
     #num_stat <- attr(verif_tdf_shiny, "num_stations")
     #sdate    <- attr(verif_tdf_shiny, "start_date")
     #edate    <- attr(verif_tdf_shiny, "end_date")
     # Surface maps (saving done in here)
     #map_df <- verif$det_summary_scores
     #print(typeof(map_df))
     #quit("no")
    #return(map_df,min_lat,max_lat,min_lon,max_lon,par_unit)
    # R cannot return several objects.. dohhh....
    return(c(verif,min_lat,max_lat,min_lon,max_lon,par_unit))
    #return(as.array(verif,min_lat,max_lat,min_lon,max_lon,par_unit))
}


surfacemap <- function(map_df,
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

{
    subtitle_da <- paste0("Average over all leadtimes : ",subtitle_str)

    if (stat_choice == "bias"){
    c_min = min(map_df$bias,na.rm=TRUE)
    c_max = max(map_df$bias,na.rm=TRUE)
    c_min = c_min - 0.1
    c_max = c_max + 0.1
    c_min = round(c_min,1)
    c_max = round(c_max,1)

    p_map <- map_df %>%
    ggplot(
        aes(lon, lat, fill=bias, size=abs(bias))
      
	  )
    p_map_col <- scale_fill_gradient2(
      paste0("Bias (",par_unit,")"),
      low  ="blue4",
      mid  ="white",
      high ="red4",
      guide = "colourbar",
      n.breaks = 7,
      limits = c(c_min,c_max)
    
		    )
  
    } else if (stat_choice == "rmse"){
    c_min = min(map_df$rmse,na.rm=TRUE)
    c_max = max(map_df$rmse,na.rm=TRUE)
    c_min = c_min - 0.1
    c_max = c_max + 0.1
    c_min = round(c_min,1)
    c_max = round(c_max,1)

    p_map <- map_df %>%
    ggplot(
        aes(lon, lat, fill=rmse, size=rmse)
      
	  )
    p_map_col <- scale_fill_gradient(
      paste0("RMSE (",par_unit,")"),
      low  ="white",
      high ="red4",
      guide = "colourbar",
      n.breaks = 7,
      limits = c(c_min,c_max)
    
		    )
  
    } else {
    print("Wrong stat choice in surface map plotting!")
    return(NULL)
  
    }
    # Define a common theme for the surface map plotting  

    p_map <- p_map + geom_polygon(
      data        = map_data("world"),
      mapping     = aes(long, lat, group = group),
      fill        = "grey100",
      colour      = "black",
      inherit.aes = FALSE
    
		    ) +
	    geom_point(
      #size=5,
      colour='grey40',
      pch=21
    
		      ) +
    coord_map("lambert", lat0=63,lat1=63,xlim = c(min_lon,max_lon),
              ylim = c(min_lat,max_lat)) +
    #print(min_lon)
    #print(max_lon)
    #print(min_lat)
    #print(max_lat)
    #coord_map("mercator", xlim = c(min_lon,max_lon),
    #          ylim = c(min_lat,max_lat)) +
    theme(
      panel.background = element_rect(fill="grey95"),
      panel.grid       = element_blank(),
      axis.text        = element_blank(),
      axis.ticks       = element_blank(),
      axis.title       = element_blank(),
      plot.title       = element_text(size=14),
      legend.text      = element_text(size=14),
      plot.subtitle    = element_text(size=12),
      legend.title     = element_text(size=14),
      strip.text       = element_text(size=14)
    
	 )+
    facet_wrap(vars(mname))+
    #facet_wrap("cca_model")+
    labs(
      title = title_str, # "paste0(ts," : ",title_str),
      subtitle = subtitle_str,
      fill = "",
      size = ""
    
	)+
    guides(size="none") # Remove size label from legend
  p_map <- p_map + p_map_col
  pngfile <- paste(paste("map",stat_choice,param,start_date,end_date,sep="_"),".png",sep="")

  ggsave(p_map,filename=pngfile,path=png_archive,width=fig_width,height=fig_height)

}
