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

Extreme_detection = function(X,timecol,prob, method) 
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
    
    DF = DF %>% mutate(Var_15ma = lead(c(rep(NA, 15 - 1),zoo::rollmean(Value,15, align = 'center')),7)) %>%   ## 15-day moving average and then long-term mean
      group_by(DOY) %>% 
      mutate(Var_LTm = mean(boot(Var_15ma,meanFunc,100)$t, na.rm = TRUE))  %>%   ## Var_LTm is the long-term mean based on a 15-day moving average-
      mutate(del_Var = Value - Var_LTm) %>%       ## deviation from a long-term mean
      mutate(Extreme = if_else(del_Var > quantile(del_Var, probs = prob*0.01, na.rm = TRUE), 'Extreme-high',
                               if_else(del_Var < quantile(del_Var, probs = (1-prob*0.01), na.rm = TRUE), 'Extreme-low', 'Not-Extreme')))  ## Assigning extreme classes based on del_Var
    
    p = DF %>% 
      ggplot(., aes(x = Date)) + 
      geom_point(aes(y = Value, fill = Extreme), color = 'black', stroke = 0, shape = 21) + 
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
      mutate(Var_15ma = lead(c(rep(NA, 15 - 1),zoo::rollmean(Value,15, align = 'center')),7)) %>%   ## 15-day moving average 
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
Tair_extreme_POT = Extreme_detection(TairData$Tair_f, TairData$Date, 95, 'POT')

## Extreme at 95th percentile using BM method---
Tair_extreme_BM = Extreme_detection(TairData$Tair_f, TairData$Date, 95, 'BM')

## Extreme at 95th percentile using MA method---
Tair_extreme_MA = Extreme_detection(TairData$Tair_f, TairData$Date, 95, 'MA')
