---
layout: page
title: "Exercise 4 - Extreme Detection"
permalink: /exercise-4/
---

In this exercise we will look at extreme values in meteorological data. First you will learn about different ways to define what is an "extreme" 
value (extreme relative to what?). Afterwards we will work with an example dataset and play around with an existing R-Script to 
get some hands on experience with the methods.

### 1. Material
You can download the required material from these sources:  
[R-Script](Extreme_detection_script.R)  
[Required Data](Tair_TS_CH-Dav_1997_2018.RData)  
[Literatur](wmo-td_1500_en.pdf)  

### 2. Methods
We will look at three different methods to determine extreme events from time series of meteorological data. The main difference between the methods is the way they define the reference, to which we compare a value to describe it as being "extreme" or not.  
Pause for a second and think about how you could describe what is an extreme value.  
  
  
  

#### 2.1 Point Over Threshold (POT)
#### 2.2. Block Maxima Method (BM)
#### 2.3. Moving Average Method (MA)

### 3. R Implementation
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