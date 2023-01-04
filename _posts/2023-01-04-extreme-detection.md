---
layout: post
title: "Exercise 3 - Extreme Detection"
categories: misc
---

In this exercise we will look at extreme values in meteorological data. First you will learn about different ways to define what is an "extreme" 
value (extreme relative to what?). Afterwards we will work with an example dataset and play around with an existing R-Script to 
get some hands on experience with the methods.

### Material
You can download the required material from these sources:  
[R-Script](Extreme_detection_script.R)  
[Required Data](Tair_TS_CH-Dav_1997_2018.RData)  
[Literatur](wmo-td_1500_en.pdf)  

```r

Extreme_detection = function(X,timecol,prob, method) 
{
  if(method == 'POT')
  {
    sprintf('Extremes detection using peak over threshold method at: %f percentile',prob)
    DF = data.frame(Value = X, Date = timecol)
    DF = DF %>% mutate(Extreme = if_else(Value > quantile(Value, probs = prob*0.01, na.rm = TRUE), 'Extreme-high',
                                         if_else(Value < quantile(Value, probs = (1- prob*0.01), na.rm = TRUE), 'Extreme-low', 'Not-Extreme')))  ## selecting values higher and lower than the percentile
    
    p = DF %>% ggplot(., aes(x = Date, y = Value)) + geom_point(aes(color = Extreme)) + geom_line(linewidth = 0.4) + theme_bw()
    print(p)
    return(DF)
  }
  ```