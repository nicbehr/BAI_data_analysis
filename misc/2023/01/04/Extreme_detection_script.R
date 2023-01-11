### Functions to detect extreme values in climate timeseries using three different methods:
#' Peak over threshold method (POT): Extremes are detected based on the absolute value as values >/< percentile (specified by 'prob' argument)
#' Block maxima method (BM): Extremes are detected based on deviations (percentile deviation specified by 'prob' argument) from long-term mean
#' Moving average method (MA): Extremes are detected based on deviations from a moving average 
#' Assume data has a daily resolution:
#' Arguments: X = Value column; timecol = date corresponding to the value column; prob = percentile (e.g. 90,95,99); method = c('POT','BM','MA')
#' A test timeseries dataset provided with this script

library(dplyr)
library(boot)
library(ggplot2)
library(zoo)

meanFunc <- function (data, i){
  d<-data [i]
  return (mean (d))   
}


Extreme_detection = function(X,timecol,prob, method, rollmean_period = 15) 
{
  if(method == 'POT')
  {
    sprintf('Extremes detection using peak over threshold method at: %f percentile',prob)
    DF = data.frame(Value = X, Date = timecol)
    DF = DF %>% 
      mutate(Extreme = if_else(Value > quantile(Value, probs = prob*0.01, na.rm = TRUE), 'Extreme-high',
                                         if_else(Value < quantile(Value, probs = (1- prob*0.01), na.rm = TRUE), 'Extreme-low', 'Not-Extreme')))  ## selecting values higher and lower than the percentile
    
    p = DF %>% 
      ggplot(., aes(x = Date, y = Value)) + 
      geom_point(aes(color = Extreme)) + 
      geom_line(size = 0.4) + theme_bw()
    print(p)
    return(DF)
  }
  
  if(method == 'BM')
  {
    sprintf('Extremes detection using block maxima at %f percentile',prob)
    DF = data.frame(Value = X, Date = timecol) %>% mutate(DOY = as.numeric(format(Date,'%j'))) # calculating DOY for long-term mean, calculate month if working on monthly data.
    
    DF = DF %>% mutate(Var_15ma = lead(c(rep(NA, rollmean_period - 1),zoo::rollmean(Value,rollmean_period, align = 'center')),7)) %>%   ## 15-day moving average and then long-term mean
      group_by(DOY) %>% 
      mutate(Var_LTm = mean(boot(Var_15ma,meanFunc,100)$t, na.rm = TRUE))  %>%   ## Var_LTm is the long-term mean based on a 15-day moving average-
      mutate(del_Var = Value - Var_LTm) %>%       ## deviation from a long-term mean
      mutate(Extreme = if_else(del_Var > quantile(del_Var, probs = prob*0.01, na.rm = TRUE), 'Extreme-high',
                               if_else(del_Var < quantile(del_Var, probs = (1-prob*0.01), na.rm = TRUE), 'Extreme-low', 'Not-Extreme')))  ## Assigning extreme classes based on del_Var
    
    p = DF %>% 
      ggplot(., aes(x = Date)) + 
      geom_point(aes(y = Value, fill = Extreme), color = 'black', size=2, stroke = 0, shape = 21) + 
      geom_line(aes(y = Value, color = 'Value'), size = 0.4) + 
      theme_bw() +
      geom_line(aes(y = Var_LTm, color = 'Long-term mean'), size = 0.8) + 
      scale_color_manual('', values = c('black','grey50'))
    
    print(p)
    
    return(DF)
  }
  
  if(method == 'MA')
  {
    sprintf('Extremes detection using "moving average" at %f percentile',prob)
    DF = data.frame(Value = X, Date = timecol) %>% mutate(DOY = as.numeric(format(Date,'%j'))) # calculating DOY for the long-term mean, calculate month if working on monthly data.
    
    DF = DF %>% 
      arrange(Date) %>%  
      mutate(Var_15ma = lead(c(rep(NA, rollmean_period - 1),zoo::rollmean(Value,rollmean_period, align = 'center')),7)) %>%   ## 15-day moving average 
      mutate(del_Var = Value - Var_15ma) %>%       ## deviation from a 15-day moving average (change the days as per requirement)
      mutate(Extreme = if_else(del_Var > quantile(del_Var, probs = prob*0.01, na.rm = TRUE), 'Extreme-high',
                               if_else(del_Var < quantile(del_Var, probs = (1-prob*0.01), na.rm = TRUE), 'Extreme-low', 'Not-Extreme')))  ## Assigning extreme classes based on del_Var
    
    p = DF %>% 
      ggplot(., aes(x = Date)) + 
      geom_point(aes(y = Value, fill = Extreme), color = 'black', stroke = 0, shape = 21) + 
      geom_line(aes(y = Value, color = 'Value'), size = 0.4) + 
      theme_bw() +
      geom_line(aes(y = Var_15ma, color = 'moving mean'), size = 0.8) + 
      scale_color_manual('', values = c('black','grey50'))
    
    print(p)
    
    return(DF)
  }
  
  if(!method %in% c('POT','BM','MA'))
  {
    print('Error: enter the method for extreme detection')
  }
}



#1. Examples----------------------
load('Tair_TS_CH-Dav_1997_2018.RData')  # load the timeseries data provided with the script
summary(TairData)

## Extreme at 95th percentile using POT method---
Tair_extreme_POT = Extreme_detection(TairData$Tair_f, TairData$Date, 60, 'POT')

## Extreme at 95th percentile using BM method---
Tair_extreme_BM = Extreme_detection(TairData$Tair_f, TairData$Date, 95, 'BM', rollmean_period = 15)

## Extreme at 95th percentile using MA method---
Tair_extreme_MA = Extreme_detection(TairData$Tair_f, TairData$Date, 95, 'MA', rollmean_period = 15)


-------------------------------------------------------------------------------
#3. Additional functions ------------------------------------------------------
-------------------------------------------------------------------------------

  
Quantiles = function(x, q){
  # Computes the quantiles defined by q for a given array of data and visualizes
  # the distribution of the data as well as the thresholds for the quantiles
  
  # separate the given q into lower and upper limits
  q_high = q
  q_low = 100 - q
  
  # find mean and sd to create a distribution from the input data
  x_mean = mean(x)
  x_sd = sd(x)
  y = dnorm(x, T1997_mean, T1997_sd)
  
  # calculate the quantiles
  qh = quantile(x,q_high*0.01, na.rm=TRUE)
  ql = quantile(x,q_low*0.01, na.rm=TRUE)
  
  # Printing out the threshold values 
  print(paste("Lower threshold of ",q_low,"%: ",sep = ""))
  print(ql)
  print(paste("Upper threshold of ",q_high,"%: ",sep = ""))
  print(qh)
  
  # Plotting distribution and thresholds
  plot(x,y)
  lines(c(ql,ql), c(0,1), col="red", lwd=4)
  lines(c(qh,qh), c(0,1), col="blue", lwd=4)
  legend("topleft", legend=c(paste("Q",q_low,sep = ""), paste("Q",q_high,sep = "")), col=c("red","blue"), lty=1, lwd=4)
}


Plot_Extremes = function(DF){
  # These are simply the plotting statements from the Extreme_Detection() method
  # You can run filtered data sets on this to plot individual years
  # The separation in conditional blocks is due to different plotting mechanisms
  # between the POT and the other two methods
  
  if ("Var_LTm" %in% colnames(DF)){
    p = DF %>% 
      ggplot(., aes(x = Date)) + 
      geom_point(aes(y = Value, fill = Extreme), color = 'black', size=2, stroke = 0, shape = 21) + 
      geom_line(aes(y = Value, color = 'Value'), size = 0.4) + 
      geom_line(aes(y = Var_LTm, color = 'Long-term mean'), size = 0.8) + 
      scale_color_manual('', values = c('black','grey50'))
    print(p)
    
  }
  else {
    p = DF %>% 
      ggplot(., aes(x = Date, y = Value)) + 
      geom_point(aes(color = Extreme)) + 
      geom_line(size = 0.4) + theme_bw()
    print(p)
  }
}


Extremes_per_year = function(df){
  # This function aggregates all data points which are categorized as high and 
  # low extremes, counts them and plots them 
  
  Extremes_DF = data.frame(matrix(ncol = 4, nrow = 0))
  colna = c("Year","Extreme_low", "Extreme_high","Not_extreme")
  colnames(Extremes_DF) = colna
  startyear = as.integer(format(as.Date(df$Date[1], format="%d/%m/%Y"),"%Y"))
  endyear = as.integer(format(as.Date(df$Date[nrow(df)], format="%d/%m/%Y"),"%Y"))
  years = startyear:endyear
  
  for (y in years){
    startdate = paste(y,'-01-01', sep="")
    enddate = paste(y+1,'-01-01', sep="")
    year = df %>% 
      filter((Date < enddate)&(Date >= startdate))
    table = table(year$Extreme)
    Extremes_DF[nrow(Extremes_DF)+1,] = c(y, as.numeric(table["Extreme-low"]), as.numeric(table["Extreme-high"]), as.numeric(table["Not-Extreme"]))
  }
  
  Year = Extremes_DF$Year
  Number_of_Extremes = Extremes_DF$Extreme_high
  Low_Extremes = Extremes_DF$Extreme_low
  Not_Extreme = Extremes_DF$Not_extreme
  
  plot(Year, Number_of_Extremes, col="red", pch=16)
  abline(lm(Extreme_high ~ Year, data=Extremes_DF), col="red", lwd=2, lty=2)
  points(Year, Low_Extremes, col="blue", pch=16)
  abline(lm(Extreme_low ~ Year, data=Extremes_DF), col="blue", lwd=2, lty=2)
  legend("topleft", 
         legend=c("Nr. of high extremes", "Nr. of low extremes", "Regression for high extremes", "Regression for low extremes"), 
         col=c("red","blue","red","blue"), 
         pch = c(16,16,NA,NA), 
         lty=c(NA,NA,2,2),
         lwd=2)
  return(Extremes_DF)
}

Plot_All_Extremes = function(df1, df2, df3){
  data1_h = df1 %>% filter(Extreme == 'Extreme-high') %>% pull(Value)
  data1_l = df1 %>% filter(Extreme == 'Extreme-low') %>% pull(Value)

  data2_h = df2 %>% filter(Extreme == 'Extreme-high') %>% pull(Value)
  data2_l = df2 %>% filter(Extreme == 'Extreme-low') %>% pull(Value)
  
  data3_h = df3 %>% filter(Extreme == 'Extreme-high') %>% pull(Value)
  data3_l = df3 %>% filter(Extreme == 'Extreme-low') %>% pull(Value)

  line_width = 2
  cols <- c("blue", "red")

  par(mfrow=c(1,3))
  plot(sort(data1_l), type="l", ylim=c(-20,25), xlim=c(0,850), lty=1 , col="blue", lwd=line_width, ylab = "Temperature of Extreme Value [°C]")
  lines(sort(data1_h), x=((length(data1_h)+1):(length(data1_h)+length(data1_l))), col="red", lwd=line_width, lty=1)
  legend( "topleft", legend=c("POT low", "POT high"), col = cols, lty=c(1,1))
  title("Extreme values for POT method")
  
  plot(sort(data2_l), type="l", ylim=c(-20,25), xlim=c(0,1500), lty=2 , col="blue", lwd=line_width, ylab = "Temperature of Extreme Value [°C]")
  lines(sort(data2_h), x=((length(data2_h)+1):(length(data2_h)+length(data2_l))), col="red", lwd=line_width, lty=2)
  legend( "topleft", legend=c("BM low", "BM high"), col = cols, lty=c(2,2))
  title("Extreme values for BA method")
  
  plot(sort(data3_l), type="l", ylim=c(-20,25), xlim=c(0,850), lty=3 , col="blue", lwd=line_width, ylab = "Temperature of Extreme Value [°C]")
  lines(sort(data3_h), x=((length(data3_h)+1):(length(data3_h)+length(data3_l))), col="red", lwd=line_width, lty=3)
  legend( "topleft", legend=c("MA low","MA high"), col = cols, lty=c(3,3))
  title("Extreme values for MA method")
}  

Total_Extremes = function(DF){
  total_extremes = table(DF$Extreme)
  print(total_extremes)
}

