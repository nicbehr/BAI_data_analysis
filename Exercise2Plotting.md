---
layout: page
title: "Exercise 2 - Data Visualization Basics"
permalink: /exercise-2/
---

In this exercise we will look at the basics of how to load datasets, prepare the data for visualization
and use the common ggplot-library for plotting

First of all, download the .csv data files and put them in the same folder
as this script.  
[Data Download](data.zip)

Then use this command to set the working directoy to the directory you have the script in:
```R
setwd(<path_to_your_script>)
```
If you are on Windows you will have to replace all \ with / !!

Now you can install the following packages, if they are not alread installed:
```R
install.packages("ggplot2")
install.packages("dplyr")
install.packages("openair")
install.packages("reshape2")

# next up we load the packages for later use:
library(ggplot2)
library(dplyr)
library(reshape2)
```

### 1. Loading and  Converting Data:

First we read in data:
```R
data_site = read.csv("data_site.csv")
data_dwd = read.csv("data_dwd.csv")
```

We convert the date from a simple string to a datetime object so R can work with it. Datetime objects
are super convenient because other than with a simple string they bring a load of functionality, allowing
you to e.g. filter based on months or years, add or subtract time offsets and much more.

```R
data_dwd$datetime = as.Date(data_dwd$datetime)
data_dwd_short = data_dwd[data_dwd$datetime >= head(data_site$datetime, n=1) &
                            data_dwd$datetime <= tail(data_site$datetime, n=1),]
```
Now we aggregate the site data to daily values:
First create a new dataset for it, we don't want to loose any data:
```R
data_site_daily = data_site
```
Now we simply remove the time by converting the datetime to a date with as.Date()
```R
data_site_daily$datetime = as.Date(data_site_daily$datetime)
```
The datetime column now looks like this:
```R
2020-09-30
2020-09-30
...
```

With that we can use the "dplyr" package to aggregate the data to daily values:  
the %>% operator just concatenates different operations
so we take the original dataset and group it by the column datetime
to aggregate the data we use the dplyr package and from that the summarize_if() 
function. For one we can specify that we only want to aggregate the numeric columns,
which excludes the datetime column. We don't want to sum up the dates!  
Secondly we pass the way we want to aggregate the data, which is the mean for 
most columns:
```R
data_site_daily_aggr = data_site_daily %>%
  group_by(datetime) %>%
  dplyr::summarize_if(is.numeric, mean) %>%
  as.data.frame()
```
For rainfall taking the mean does not make sense, we want to have the sum of the
rainfall as aggregated values. To get these, we can use basically the same syntax,
only switching up the summarize_if() for summarize() and the mean for the sum().
```R
site_precip_daily = data_site_daily %>%
  group_by(datetime) %>%
  dplyr::summarize(RR = sum(RR)) %>%
  as.data.frame()
```
Now we can just set the precipitation column in our aggregated data to our just 
derived column:
```R
data_site_daily_aggr$RR = site_precip_daily$RR
```

### 2. Plotting:

#### 2.1 Line Plots
First here are a few examples of classic line plots, as you have already seen them
in the tutorial. I added a bunch of customization so you can grab from it, whatever
you need later for your own plots:
First a line plot of temperature data for one site:
```R
T_figure_single = ggplot()+ 
  geom_line(data = data_dwd_short, aes(x=datetime, y = T2M))+ 
  ylab("T [°C]")+
  scale_x_date(date_breaks = "3 months" , date_labels = "%b-%y")+
  ggtitle("Temperature", subtitle="at DWD station Ahaus")
print(T_figure_single)
```

now we add another line to the same plot and add some legends to it,
to make clear which line is what. You can try around and change the colors
of the lines or the title of the legend in the scale_color_manual() function
```R
T_figure_multiple = ggplot()+ 
  geom_line(data = data_dwd_short, aes(x=datetime, y = T2M, color="DWD"))+ 
  geom_line(data = data_site_daily_aggr, aes(x=datetime, y=T, color = "Site"))+
  scale_color_manual( name="Source", values = c("DWD" = "blue", "Site" = "red"))+
  ylab("T [°C]")+
  scale_x_date(date_breaks = "3 months" , date_labels = "%b-%y")+
  ggtitle("Temperature", subtitle="at DWD station Ahaus and site Amtsvenn")
print(T_figure_multiple)
```
note the super handy "scale_x_date()" function, that makes the x-scale more 
readable with a super handy function. Compare the x-axis in this graph with 
the previous one.

Now lets do the same for relative humidity:
```R
RF_figure = ggplot()+ 
  geom_line(data = data_dwd_short, aes(x=datetime, y = RF, color="DWD"))+ 
  geom_line(data = data_site_daily_aggr, aes(x=datetime, y=RF, color = "Site"))+
  scale_color_manual( name="Source", values = c("DWD" = "blue", "Site" = "red"))+
  ylab("relative humidity [%]")+
  scale_x_date(date_breaks = "3 months" , date_labels = "%b-%y")+
  ggtitle("Relative humidity", subtitle="at DWD station Ahaus and site Amtsvenn")
print(RF_figure)
```
You can just grab the above code, and create the same plot for precipitation.
Just copy-paste the code, change the labels and title and your done!

One way to see whether the two sites are comparable is to look at the differences
between the values at both sites. Therefore we first create a new dataframe with
the differences and then plott the data in a simple plot - here is one example
for temperature:
```R
T_diff = data.frame(
  datetime = data_dwd_short$datetime,
  T_diff = data_dwd_short$T2M - data_site_daily_aggr$T
)
T_diff_figure = ggplot()+ 
  geom_line(data = T_diff, aes(x=datetime, y = T_diff))+ 
  ylab("Temperature difference [°C]")+
  scale_x_date(date_breaks = "3 months" , date_labels = "%b-%y")+
  ggtitle("T diff", subtitle="between DWD station Ahaus and site Amtsvenn")
print(T_diff_figure)
```
Now you can do the same for e.g. relative humidity, rainfall etc.

#### 2.2 Histograms

Lets look at one more kind of plot. If we want to look at the frequency of an 
event occuring, a histogram can be a good choice. The observed values get binned
in certain intervals and on the y-axis we count, how often this value occurs in 
the data. We can use that e.g. to get an overview of the dominant wind direction.

First we create a new dataframe that extracts only the wind-direction and wind-speed
information from the site data:

```R
wind_data = data.frame(
  ws = data_site_daily_aggr$F,
  wd = data_site_daily_aggr$WD
)
```
Now we create the histogram:
```R
WD_figure = ggplot(wind_data, aes(x=wd)) +
  geom_histogram()+
  xlab("wind direction [°]")+
  ggtitle("Wind direction in Amtsvenn")
print(WD_figure)
```
You can look at some further customization options in the documentation or for example here: 
[Link: sthda.com Intro to Data Visualization](http://www.sthda.com/english/wiki/ggplot2-histogram-plot-quick-start-guide-r-software-and-data-visualization)

