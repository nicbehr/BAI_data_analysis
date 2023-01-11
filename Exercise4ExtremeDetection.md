---
layout: page
title: "4 - Extreme Detection"
permalink: /exercise-4/
---

In this exercise we will look at extreme values in meteorological data. First you will learn about different ways to define what is an "extreme" 
value (extreme relative to what?). Afterwards we will work with an example dataset and play around with an existing R-Script to get some hands on experience with the methods.

#### Table of Contents
1. [Material](#1-material)
2. [Background](#2-background)
3. [Methods and Implementation](#3-methods-and-implementation)
  3.1. [Peak Over Threshold (POT)](#31-peak-over-threshold-pot)
  3.2. [Block Maxima (BM)](#32-block-maxima-method-bm)
  3.3. [Moving Average (MA)](#33-moving-average-method-ma)


### 1. Material
You can download the required material from these sources:  
[R-Script](Extreme_detection_script.R)  
[Required Data](Tair_TS_CH-Dav_1997_2018.RData)  
[Literatur](wmo-td_1500_en.pdf)  

### 2. Background
We will look at three different methods to determine extreme events from time series of meteorological data. The main difference between the methods is the way they define the reference, to which we compare a value to describe it as being "extreme" or not.  
Pause for a second and think about how you could describe what an extreme value is.  
  
There are several ways to think about extreme values. An extreme value can simply be the highest/lowest value in a finite set of data. Think for example about testing the highest speed that a car reaches on a test drive. Here the absolute peak value would be a reasonable value of interest.  
  
In meteorological time series we are often interested in a range of extreme values. In other words, we are interested in the values in the tails of the distribution of our sample data, which exceed a certain threshold. It is important to consider the distribution of our underlying dataset and the question we actually want to answer. 

Our example dataset comprises of air temperature data from 1997 to 2020. If we are interested in the extreme values with respect to this whole time period, we can simply look at the distribution of all the data, determine a threshold and see which datapoints are above the upper or below the lower threshold. 

However, we might also be interested in the months with extreme temperatures. Because our distribution includes winter and summer data, extreme temperatures in spring and autumn will probably not be considered in this approach. For these we would have to create data distributions of seasonal, monthly or even daily data to evaluate extreme events on the respective time scale. This will become more obvious when we look at the methods.

<details>
<summary>
Read More: Extreme value return periods
</summary>
Another approach is the evaluation of extreme values and their probabilities based on historical data. Relating these probabilities to the time series of the data produces "return periods", frequencies in which the extreme values are expected to occur. As an example, requirements for buildings often include a resistance to weather extremes with a certain return period. Making up a case, wind turbines would be built that they can withstand windspeeds with a "return level" in a "return period" of 1 in 10.000, meaning the chance that such a windspeed occurs in a year would be 0.01%.
In meteorological data 
</details>

### 3. Methods and Implementation
Lets now look at three different methods to analyze extreme events in our sample dataset. We will talk about the reasoning and the R implementation of the methods. The first section is a general introduction to the code. We will then go through each method. In the beginning of each chapter you can click on the little arrow to unfold the code for the specific method. This way you can always quickly refer to the code.

In the code you have downloaded is a method called "Extreme_detection" which takes the arguments X, timecol, prob and method. 
```R
Extreme_detection = function(X,timecol,prob,method) 
```
The arguments for this functions are the following:
- **X** is the series of data which is to analyzed for extremes
- **timecol** is the column of data in which the time is stored 
- **prob** defines the extreme threshold in terms of percentiles of the data given as integers, e.g. 80, 90, 95. E.g. passing in 90 will define everything above a range of values that includes 90% and below a range that includes the lowest 10% as extreme high/low values.
  <details>

  <summary>
  Read more: What are quantiles?
  </summary>

  A quantile is a subset of the given data, that contains a certain percentage of the distribution of the data. E.g. in the following figure, everything left of the red line is in the q10 percentile, the lowest 10% of the data. Everything up to the blue line is in the q90, the quantity that comprises of 90% of the data.
  ![A test image](.\misc\2023\01\05\quantiles.png)
  You can paste the following function in your code after you loaded the data and play around with the visualization of the quantiles:
  ```R
  Quantiles = function(x, q_low, q_high){
    x_mean = mean(x)
    x_sd = sd(x)
    y = dnorm(x, T1997_mean, T1997_sd) # This function creates the y-values of the normal distribution given our data, the mean and the standard deviation
    qh = quantile(x,q_high*0.01) # here we calculate the higher quantile threshold
    ql = quantile(x,q_low*0.01) # here we calculate the lower quantile threshold 

    above_qh = TairData$Tair_f[TairData$Tair_f > qh] # filter the datapoints from our set which are above qh
    below_ql = TairData$Tair_f[TairData$Tair_f < ql] # filter the datapoints from our set which are below ql
    print(paste("Percentage of values below q",q_low,": ",sep = ""))
    print(length(above_q90) / length(TairData$Tair_f) * 100)
    print(paste("Percentage of values above q",q_high,": ",sep = ""))
    print(length(below_q10) / length(TairData$Tair_f) * 100)

    plot(x,y)
    lines(c(ql,ql), c(0,1), col="red", lwd=4)
    lines(c(qh,qh), c(0,1), col="blue", lwd=4)
    legend("topleft", legend=c(paste("Q",q_low,sep = ""), paste("Q",q_high,sep = "")), col=c("red","blue"), lty=1, lwd=4)
    }

  Quantiles(TairData$Tair_f,10,90)
  ```
  </details>
- **method** defines which extreme detection will be used
  - "POT" for Point Over Threshold
  - "BM" for Block Maxima 
  - "MA" for Moving Average.

The structure of the method is rather simple. Depending in the given method argument, one of three blocks of code will be executed. The branching is done with if-conditionals:
```R
Extreme_detection = function(X,timecol,prob, method) 
{
  if(method == 'POT')
  {
    ...RUNS POT CODE
  }
  
  if(method == 'BM')
  {
    ...RUNS BM CODE
  }
  
  if(method == 'MA')
  {
    ...RUNS MA CODE
  }
  
  if(!method %in% c('POT','BM','MA'))
  {
    print('Error: enter the method for extreme detection')
  }
}
```
If an invalid method is chosen, the last block is executed simply printing an Error-message.

Below the function definition the example dataset is loaded and you are given some example calls to the function:
```R
#1. Examples----------------------
load('Tair_TS_CH-Dav_1997_2018.RData')  # load the timeseries data provided with the script
summary(TairData)

## Extreme at 95th percentile using POT method---
Tair_extreme_POT = Extreme_detection(TairData$Tair_f, TairData$Date, 95, 'POT')

## Extreme at 95th percentile using BM method---
Tair_extreme_BM = Extreme_detection(TairData$Tair_f, TairData$Date, 95, 'BM')

## Extreme at 95th percentile using MA method---
Tair_extreme_MA = Extreme_detection(TairData$Tair_f, TairData$Date, 95, 'MA')
```
Finally, in the very end of the file you find a number of additional functions which will be used in the exercises. 

#### 3.1 Peak Over Threshold (POT)
<details>

<summary>
Peak Over Threshold Codeblock
</summary>

```R
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
```
</details>

The first approach is the Point Over Threshold (POT) method. We define fixed thresholds for the dataset, defining the upper and lower bounds above or below which values will be considered extreme. The boundaries are defined by the quantiles we provided as an argument to the function.

So what is happening in the code? 

Very simple: First we create a new Dataframe with our data and the respective dates.  This dataframe is fed into a pipeline where we "mutate" the dataframe. In the mutation, a new column is added called "Extreme". This column is then populated through a conditional function, the if_else() function from the dplyr package. Here the code gets a bit complicated, because there is a second if_else() inside the first if_else() function. It is a "nested" function.  It works like this:  
Normally the if_else() function checks a condition and for all values passed and returns one of two values, depending on whether the condition is true or false. Consider this:
```R
x = c(-5,-2,2) # x now is a vector [-5,-2,2]
if_else(x > 0, "positive", "negative") # Returns "positive" when provided value > 0, else returns "negative"
Output:
negative
negative
positive
```
So now when we have a nested if_else() function the "inner" function gets executed when the first condition returns false:
```R
x = c(-5,-2,0,2) # x now is a vector [-5,-2,0,2]
if_else(x > 0, "positive", # When the number is bigger than 0, function returns "positive", else second if_else() is executed
  if_else(x == 0, "null","negative")) # When the number is equal 0 returns "null", else returns "negative"
Output:
negative
negative
null
positive
```
In our POT-codeblock we first examine if the datapoint is bigger than the upper quantile threshold. If so, it sets the value in the "Extrem" column to "Extreme-high". If not, the second if_else block checks whether the value is lower thant the lower quantile boundary. If so, it sets the value of the "Extreme" column to "Extreme-low", else to "Not-Extreme".

Go ahead and run the example for the POT method:
```R
## Extreme at 95th percentile using POT method---
Tair_extreme_POT = Extreme_detection(TairData$Tair_f, TairData$Date, 95, 'POT')
```
You will get a plot of the data with marked extreme low and high values (see spoiler below) as well as a dataframe that contains the "Extreme" column along with the original data.
<details>

<summary>
Output Figure:
</summary>

![A test image](.\misc\2023\01\05\extreme_POT.png)
*Figure 1: Extreme values based on the whole dataset POT method*
</details>
As expected you can see that this plot gives us information about the extreme values with respect to the whole timeline. 

---------
#### Exercise

1. Lets fiddle with the code for a bit. Change the **prob** parameter and see how the output changes. How many extreme values do you expect when setting prob to 50? Think about it and then run the function with that quantile.
2. Grab the function from the "Starter Code" below and try to change it in such a way that it plots the number of high, low and non-extreme events per year. Give it the output of your POT-run as parameter E.g. run the POT function for 75, 85 and 95, save the outputs in separate variables (e.g. POT_75, POT_85 etc.) and then call the function Extremes_per_year with these variables as parameters. If you get stuck you can find a solution at the end of the exercise. 

<details>

<summary>
Starter Code
</summary>

```R
Extremes_per_year = function(df){
  # First we build an empty dataframe with our column names
  Extremes_DF = data.frame(matrix(ncol = 4, nrow = 0))
  colna = c("Year","Extreme_low", "Extreme_high","Not_extreme")
  colnames(Extremes_DF) = colna

  # Now we filter the start and end year from the given dataframe. This gives flexibility so we can use other dataframes with different timescales
  startyear = as.integer(format(as.Date(df$Date[1], format="%d/%m/%Y"),"%Y"))
  endyear = as.integer(format(as.Date(df$Date[nrow(df)], format="%d/%m/%Y"),"%Y"))

  # Now we build a vector comprising of our years
  years = {insert here}:{insert here}  # <==================  insert correct values to create a vector of all years
  
  for (y in years){   
    startdate = paste(y,'-01-01', sep="")
    enddate = paste(y+1,'-01-01', sep="")
    year = df %>% 
      filter((Date < {insert here})&(Date >= {insert here}))  # <==================  insert correct values to filter the date on
    table = table(year$Extreme)
    Extremes_DF[nrow(Extremes_DF)+1,] = c(y, as.numeric(table["Extreme-low"]), as.numeric(table["Extreme-high"]), as.numeric(table["Not-Extreme"]))
  }
  
  Year = Extremes_DF$Year
  Number_of_Extremes = Extremes_DF$Extreme_high
  Low_Extremes = Extremes_DF$Extreme_low
  Not_Extreme = Extremes_DF$Not_extreme
  
  plot({insert here}, {insert here}, col="red", pch=16) # <==================  insert correct values to plot years vs high extremes
  abline(lm(Extreme_high ~ Year, data=Extremes_DF), col="red", lwd=2, lty=2)
  points({insert here}, {insert here}, col="blue", pch=16) # <==================  insert correct values to plot years vs low extremes
  abline(lm(Extreme_low ~ Year, data=Extremes_DF), col="blue", lwd=2, lty=2)
  legend("topleft", 
         legend=c("Nr. of high extremes", "Nr. of low extremes", "Regression for high extremes", "Regression for low extremes"), 
         col=c("red","blue","red","blue"), 
         pch = c(16,16,NA,NA), 
         lty=c(NA,NA,2,2),
         lwd=2)
  return(Extremes_DF)

  # Example for calling the functions:
  POT_75 = Extreme_detection(TairData$Tair_f, TairData$Date, 75, 'POT')
  Extremes_per_year_POT = Extremes_per_year(POT_75)
}
```
</details>

Compare the outputs of your function calls. Look at the values which are defined as extreme. What seems to an appropriate threshold for an extreme quantile? Is the regression plotted in the yearly extremes statistically solid? If you want, you can further fiddle with the code and remember the "summary()" method, that can describe a linear model. Can we take away something from the plots and our data?

<details>

<summary>
Solution
</summary>

```R 
Extremes_per_year = function(df){
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

  ```
</details>


----------

#### 3.2. Block Maxima Method (BM)

<details>

<summary> Block Maxima Codeblock </summary>

```R
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
  ```
  </details>

The next method we are looking at is the "Block Maxima" method. As the name states, we are looking at a certain "block" of data and find the maxima based on the defined threshold of the values in this block. There are several ways we could define these reference blocks. For example we could look at every year individually and find the extreme values for these. We would get an array of the hottest and coldest days of each year separately.
If we where more interested in extreme values across years, we could for example define a block as data from each season across the years. So the block "spring" would consist of data from 01.03. to 31.05. across all the years in the dataset. We could then find extremes based on the quantiles of the seasonally data and separate e.g. extreme values in spring and autumn from the overshadowing extreme values in winter and summer.

In our example code the blocks are defined as the values for each single day across all the years. The procedure is as follows: 

**Step 1**
In the first line we again create a dataframe with the data, a date column and then add a new column called "DOY" with a mutation, that gives each date a value of 1 to 365. We can later use these values to calculate a mean for each year across the seasons:
``` DF = data.frame(Value = X, Date = timecol) %>% mutate(DOY = as.numeric(format(Date,'%j'))) # calculating DOY ```

**Step 2**
Next a second mutation is being done, which creates the column "Var_15ma". This is the 15 day moving average around every day. Moving average means that the "window" of data we are calculating the mean from varies. For each data point 
``` DF = DF %>% mutate(Var_15ma = lead(c(rep(NA, 15 - 1),zoo::rollmean(Value,15, align = 'center')),7)) # 15-day moving average and then long-term mean ``` 
Through this, we accquire a smoothing of the daily temperature values and make the underlying dataset for our daily temperature distribution more broad. The reasoning is the following: 
We want to create a representative dataset for daily temperature values across the years. If we use the single day for each year, we have a dataset of 18 datapoints which can easily include heavy outliers. By using a moving average of 15 days we enhance our dataset for each day by a factor of 15 to 270 datapoints, still restricted to a pretty small time window. While it does reduce the impact of individual extremely hot or cold days, it is more likely to representatively capture the state of the atmosphere around the time of interest.

**Step 3**
The next step creates the column "Var_LTm". This is the column representing the long-term mean (LTm) for each day of the year: 
```R 
mutate(Var_LTm = mean(boot(Var_15ma,meanFunc,100)$t, na.rm = TRUE))  %>%   ## Var_LTm is the long-term mean based on a 15-day moving average-
```
This is a bit of a nested function call because we use a method called "bootstrapping". Bootstrapping means that we take several random subsamples from the data we have and calculate the mean for each subsample. Then we can look at the distribution of these means e.g. to find confidence intervals. This allows us to asses how representative our mean value for the whole dateset is. Finally, we can calcualte the mean of the means of the subsamples and use that as our final mean value. The function looks like this:
```R
mean(boot(Var_15ma,meanFunc,100)$t, na.rm = TRUE))
```
The order in which these functions are executed is form the inside out: first the function ```boot()``` is called with the parameters Var_15ma, meanFunc and 100. This means we take 100 subsamples from the column Var_15ma and call the function ```meanFunc()``` on them. This is just a function that calculates the mean of a vector. With the $t after the function call we access the resulting vector of 100 means which is returend from the boot() function. Then we simply calculate the mean from these means and ingore the NA-values with ``` mean(..., na.rm = TRUE)```.

**Step 4**
Finally we calculate the deviation of each datapoint from the previously derived mean and assign it one of the categories "Extreme-high", "Extreme-low" or "Not-Extreme", just like we did in the POT approach. The rest is plotting.

---
### Exercises

1. After using POT and the BM method with daily blocks, which method do you expect to yield more extreme values per year? Think about it and then use the previously built Extremes_per_year() function to check your hypothesis
2. The Extreme_Detection() function has one parameter called "rollmean_period" which has a default value of 15. This means that the time window on which the mean for each day is calculated is 15 days, the day + the 7 days before and after. Think about how it might affect the outcomes if you set this value to 1 or to 365. To evaluate, you can use the extra functions given in the end of the script, Plot_Extremes() and Quantiles(). For example run the Extreme_Detection() with the rollmean_period of 1 and use the Plot_Extremes() function to plot a specific year like this:
```R
Plot_Extremes(Tair_extreme_BM %>% filter(Date > '2017-01-01'))
```


---

#### 3.3. Moving Average Method (MA)

<details>

<summary>
Moving Average Codeblock
</summary>

```R
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
  ```
  </details>
The final method we will look at is the moving average method. As the name already states, here the extremes are detected on a more temporally constrained basis, the moving average around each datapoint. Take a look at the code block above for the moving average method. Everything used here was already used in the blocks before, only the deviation from the mean (the "del_var") is now computed differently.  
---
### Exercise

1. Think about how using a smaller time reference window might affect the extreme value detection. Would you expect extreme values in this approach to be more or less frequent than in the block averaging method? Then run the detection function and save the output in a new variable. Finally use the given evaluation function Total_Extremes() and pass it the output. Was your guess right?
2. You have now run all three methods. In the evaluation functions you have a given function "Plot_All_Extremes()". Call it with your POT, BA and MA outputs as arguments and look at the temperature ranges which where categorized as extreme values. Write up a very short summarization. 
3. Change the parameter rollmean_period of the extreme detection function with the MA method to 365 and pass that output to the "Plot_All_Extremes()" function. How do you explain the output in comparison to the other methods?
