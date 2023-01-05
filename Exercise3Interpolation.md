---
layout: page
title: "3 - Interpolation and Gap Filling"
permalink: /exercise-3/
---

In this exercise we look at interpolation and the rather time-series specific topic of data-gap filling.  
In time-series data we often have gaps due to a variety of reasons. They can result from instrumental issues or maintenance times or unfavorable weather conditions which leads to data being discarded. These data gaps can be filled with statistical methods.

In this lesson exercises are not completely separated from the content. Just follow along, grab the code and in some parts you will get snippets to run and fiddle with yourself.

First load up the libraries we will need:
```R
library(dplyr)
library(ggplot2)
```
Before we start plotting data we will see, how we can deal with missing values which are already handled by the institution
meaasuring the data, e.g. the DWD

### 1. Loading and  converting data:
First we read in data:
```R
data_site = read.csv("data_site.csv")
data_dwd = read.csv("data_dwd.csv")
data_dwd$datetime = as.Date(data_dwd$datetime)
```
Now we will create some missing data with a placeholder value of -888.88 as an example:
```R
data_dwd_with_placeholders = data_dwd
data_dwd_with_placeholders$RR[250:350] = -888.88
```

In this example you see how this data gets plotted. Autoformat of the axes is not working and the data
is barely readable.
```R
bad_fig = ggplot(data_dwd_with_placeholders, aes(datetime, RR))+
    geom_line()+
    ylab("Precipipitation [mm]")+
    scale_x_date(date_breaks = "12 months" , date_labels = "%y-%m")
print(bad_fig)
```

lets look at the first way to solve this.
first we identify the problematic values, e.g. by searching for unrealistic values:

```R
data_dwd_with_placeholders[data_dwd_with_placeholders$RR <= -500,]
```
now that we know, that the placeholder values is -888.88 we can find all indices where the column contains this value:
```R
indices = data_dwd_with_placeholders$RR == -888.88
```
we can use these indices to easily replace these values by NA
```R
data_dwd_with_placeholders$RR[indices] = NA
```


To show that the line plot now automatically does not draw this gap, we slice some rows containing the 
missing values from the placeholder dateset:
```R
slice_data_dwd_with_placeholders = data_dwd_with_placeholders[200:400,]
```
Now you can see that the autoformatting of the axes works and the data is left out when plotting:
```R
better_fig = ggplot(slice_data_dwd_with_placeholders, aes(datetime, RR))+
    geom_line()+
    xlab("Date [yy-mm-dd]")+
    ylab("Precipipitation [mm]")+
    scale_x_date(date_breaks = "1 months" , date_labels = "%y-%m-%d")
print(better_fig)

```

### 2. Gap Filling, interpolation and modelling

In the next part we will discuss how we can work with timeseries that have gaps of different sizes.
This is a regular task when working with long-time observations and there are a couple of options,
depending on what data is available to you and what is the final evaluation goal you have in mind.

#### 2.1: Simple linear interpolation

You do basic interpolation in your every day live. You want to bake a cake and only find a receipe for an 8 person cake,
but only 3 friends are coming over for cake time. In the receipe you have to use 1 kg of flour. Intuitively you can 
see that since you will only be four at the table, you can alter the receipe and only use 500 g of flour.
And already did you do some interpolation! 
What you easily did right away in your head could be mathematically formulated as:
y = 125 * x
where y is the amount of flour in grams and x is the number of people eating cake.

The formula for an interpolation between two points (x1,y1) and (x2,y2) at a specific point
(xn, yn) is:
<div>$$ yn = y1 + \frac{(y_{2}-y_{1})}{(x_{2}-x_{1})} * (x_{n} - x_{1}) $$</div>
We simply construct a straight line where y1 is our y-intercept, the slope is derived 
from the two points with the well known slope-formula "m = (y2-y1)/(x2-x1)", and our x value 
on this constructed line is difference between the point we want to look at minus the starting point

Note that in this form of y = mx + b we only have one x which we use to explain our y-value. We have one "predictor".
Using only one predictor gives us a so called simple linear regression. This is a super simple form of interpolation 
and of course leaves a lot of information aside. 



Lets look at a simple example of how to actually do linear interpolation in R:  
  
First we create a dataset of x and y values which represents the true values  
```R
y = c(1,2,0,13,4,10,19,15,13,21,27)
x = c(1,2,3,4,5,6,7,8,9,10,11)
data_full = data.frame(
    x,
    y
)
```
Now we build a second dataset in which we leave singular points out. This would in a real scenario be the data that 
we actually have
```R
y = c(1,2,0,NA,4,NA,19,15,13,NA,27)
x = c(1,2,3,4,5,6,7,8,9,10,11)

deleted_indices = c(4,6,10)

data_reduced = data.frame(
    x,
    y
)
```


lets take a quick look at the two datasets:

First we create as imple line plot of the reduced data
```R
plot(data_full$x, data_full$y, col="red", xlab="X", ylab="Y", pch=19)
```
Now we add the missing values in red to the plot.
We can make these points red using the "col" argument for "color" and define the symbols with the "pch" argument.
You can find a list of all available symbols e.g. here:  
[Link: sthda.com point shapes](http://www.sthda.com/english/wiki/r-plot-pch-symbols-the-different-point-shapes-available-in-r)
```R
points(data_reduced$x, data_reduced$y, col='black', pch=19)
```
Finally we add a legend to the plot so we know what is what. We can use the inbuilt method "legend()"
The first two arguments 1 and 28 are the x and y positions of the legend. To the argument "legend" we pass
a vector of strings, which is the legend text. Then we can again use the col and pch arguments to define the 
colors and symbols of the legend according to our plot.
```R
legend(1,28, legend=c("original data", "deleted data"), col=c("black", "red"), pch=c(19,19))
```

To do a linear interpolation between each adjacent points you can use a simple inbuilt function in R, the approx()
function: 
```R
prediction = approx(data_reduced$x, data_reduced$y, method="linear", n=11)
plot(data_full$x, data_full$y, col="black", xlab="X", ylab="Y")
points(data_reduced$x, data_reduced$y, col='red', pch=19)
```
Since we can use the approx() function to create a pretty much infinite nubmer of approximations between the 
points we will use a line to visualize it. We can do that with the lines() function and pass it our predicitons:
```R
lines(prediction$x, prediction$y)
```
Now we add a legend again. To specify the line type in the legend we can use "lty" argument. Note that 
we have to keep the order of entries from our "legend" keyword and add an entry in pch and lty for each legend
entry. For the point data we add "NA" in index 1 and 2 in lty, and in pch we add "NA" in the third position,
as that is the line and not a point.
```R
legend(1,28, 
       legend=c("deleted data", "remaining data", "interpolation line"), 
       col=c("black", "red", "black"), 
       lty=c(NA,NA,1), 
       pch=c(1,16, NA))
```

In this approach all we did was to draw straight lines between adjacent points. As you see, for the first point
the prediction was rather poor, the other two where pretty well reconstructed.
However, with this approach we leave all the information the other points give us about the data aside. 
Imagine for example that you have a timeseries where you measure temperature at midnight and at 12AM.
If one datapoint was missing, you would connect the two night time temperatures and interpolate the daytime
temperature way off.

A simple measure of how well our model performed is to look at the residual standard error. We calculate it
as

$$ \sqrt{\frac{\sum_{i=1}^n (y[i] - ypredicted[i])^2}{df}} $$

where y is the true value, ypredicted is the predicted y value, and df is the degrees of freedom. Df is the total
number of observations used for the model fitting minus the number of model parameters. Since we have 11 total 
data points of which 3 are missing and we have 2 model parameter we have 6 degrees of freedom.


```R
RSE_linerp = sqrt(sum((data_full$y[deleted_indices] - prediction$y[deleted_indices])^2) / 6)
RSE_linerp
```

#### 2.2: Simple linear models

Another approach would be to create a linear model that builds not only on the two points but rather the whole of the 
dataset that we have available.

So what we want to achieve, is to find a function that constructs our unknown data points based on the data we have
availabel in the best possible way. That means, that we want to have as little errors in our model as possible. 
The error is usually measured as the "sum of squared errors" (SSE) which is the distance between a true value 
and the predicted value. We square it to avoid negative and positive values counterbalancing each other. 


Looking at an array of n data points we can write
$$ SSE = \sum_{i=1}^n (y(i) - b - m * x(i))^2 $$

y(i) is the true y value at the predicted point, b is the y-intercept of the linear model, 
m is the first coefficient of the linear model and x(i) is the x-value at the predicted point. 

Since we want to find the straight line, that MINIMIZES the SSE, we call a procedure like this
a "minimization problem" and specifically the estimation of this line is called a "least squares estimation".




In the easiest way of fitting a linear model to such a dataset, it all depends on the mean of our dataset.
To derive the model parameters we can use the following relations where we replace b with alpha and m with beta
(as that is the general standard). Also we will now denote the predicted y-value with a ^ on top of that, which is
the common standard in literature. Sometimes this is also referred to as y_hat.

$$ \hat{y}_{i} = \alpha + \beta * x_{i} $$

$$ \alpha = \bar{y} - (m \bar{x}) $$

$$ \beta = \frac{\sum_{i=1}^n (x_i - \bar{x})(y_i - \bar{y})}{\sum_{i=1}^n (x_i - \bar{x})^2} $$



If we would do it by hand, we would simply plug in all the numbers we have into the expression for beta and
use the result to derive our alpha

Luckily, we have inbuilt functions in R for that.
To fit a linear model to the data we have in the reduced dataset we can use a simple inbuilt method:
```R
model <- lm(data_reduced$y ~ data_reduced$x, data = data_reduced)
```
We provide the dataset that has the information to the "data" argument and specify, which column is supposed
to be explained by which other column (or which column is dependent on which other column) with data_reduced$y ~ data_reduced$x.

When we print the model we see the paramters of our linear line, that R has fitted for us:
```R
model$coefficients
```

So we  want to have y-values corresponding to the x-indices of 3, 6 and 10
We compute them by passing the x values at these indices (which are just the indices in this case) to the function
of our linear model:
```R
y_hat_manual = 2.528 * deleted_indices -4.411
y_hat_manual
```


The same effect can be achieved by using the "predict" function and passing it our model as well as the dataframe
with the missing values
```R
y_hat = predict(model, newdata = data_reduced) #Predictions on Testing data
y_hat[deleted_indices]
```



We can look at out interpolated values by plotting them as red dots together with our reduced dataset:
```R
plot(data_reduced$x, data_reduced$y, xlab="X", ylab="Y")
points(deleted_indices, y_hat[deleted_indices], col='red', pch=19)
legend(1,28, legend=c("original data", "modelled data"), col=c("black", "red"), pch=c(1,19))
```


We can visualize the predicted values of our model as a line by displaying the first and last values of our
vector as a line plot:
```R
plot(data_reduced$x, data_reduced$y, xlab="X", ylab="Y")
points(deleted_indices, y_hat[deleted_indices], col='red', pch=19)
points(deleted_indices, data_full$y[deleted_indices], col='black', pch=19)
lines(c(1,11),y_hat[c(1,11)])
legend(1,28, 
       legend=c("reduced data", "modelled data", "true data", "regression line"), 
       col=c("black", "red", "black"), 
       lty=c(NA,NA,NA,1), 
       pch=c(1,16,16,NA))
```


Finally we need to look at statistical metrics to find out, how well our linear model performed.
Luckily we can easily get a comprehensive overview of statistical metrics in R by calling the summary() 
function on the linear model:
```R
summary(model)
```

A few things we can take from this are:  
**a)** The adjusted R^2 is 0.8076, which is the ratio of the sum of squared errors divided by the sum of squared
deviations from the mean. You can say that r_squared is a measure of how much of the variance in the original
data is reflected by the model. In this case, as our model is just a line, the amount of variance captured in the model
and stems from the linear trend that is inherent in the original data.

Whether an R^2 is good or bad depends heavily on the application. If you are a social scientist and work on 
voter behaviour an r_square of 0.65 may be spectacularly good. If you want to calibrate your measurement device
and the reference and measured values have an r_square of less than 0.85 you might want to check it again...

**b)** The residual standard error is the square root of the sum of squared errors divided by the degrees of freedom. 
In plain words you could say that it shows how much you can expect the model to be wrong on average. So when
we apply our model we have to take care not to overinteprete small changes in our modelled data.

We wont go much deeper into statistical metrics here. But as you can see, this model does represent certain characteristics
of the data regarding its variance (judging by the rsquare of > 0.8)
but has a pretty high average error of more than 4 while we are in a 
domain of data that only reaches from 1 to 27.



### Part 2.3: Multiple linear models

Lets look at another way to make our models a bit more flexible
With lm() we created a linear model with only one parameter. Obviously that did not catch all of the variance in our 
data. In reality we often have more variables at hand which can help us explain the measure of interest.
For example to fill gaps in temperature data instead of using only the time of day, we could add variables
such as the incoming radiation or the relative humidity of the air.



First lets load in some actual data and aggregate it to daily values:
For the aggregation we can use the same function we used in the previous lecture:

First we make a copy of the original dataframe to a new variabl to work non-destructive (meaning, we keep the original
data intact)
```R
data_site_daily = data_site
```

First we set the datetime column in our copied dataframe to a "Date" type. That gets rid of the time information and 
only leaves us with yyyy-mm-dd information
```R
data_site_daily$datetime = as.Date(data_site_daily$datetime)
data_site_daily

```


Now we can use a dplyr pipeline to do the actual resampling of the data:
We insert the dataframe with daily values into the pipeline with the %>% operator

```R
data_site_daily = data_site_daily %>%
```
Now we use the group_by() function to grab all the data that belongs to each day
```R
  group_by(datetime) %>%
```
Then we use another dplyr function, summarize_if() to aggregate the data. To the function we pass two arguments:
1. we say that we only want to summarize if the data is numeric. Thereby we prevent that e.g. the date column is summarized as well
2. We pass an argument that defines, HOW we want to aggregate the data. In this case "mean", taking the average
for each day as the new value
```R
  dplyr::summarize_if(is.numeric, mean) %>%
```
Finally we specify the datatype of our output, which is a data.frame
```R
 as.data.frame()
```
Just like before, for precipitation we do not want the data to be averaged but rather summarized.
We do the exact same pipeline as above, except this time we use th dplyr summarize() function instead of the 
summarize_if() function and pass it the sum() function as the method of aggregation.
```R
site_precip_daily = data_site_daily %>%
  group_by(datetime) %>%
  dplyr::summarize(RR = sum(RR)) %>%
  as.data.frame()
data_site_daily$RR = site_precip_daily$RR
```



Once again I replace some values by NA to create a gap in the data for temperature and also for the dewpoint temperature, as that is calculated from air temperature.

First we define a range of values to delete:
```R
removed_indices = c(320:360)
```
Now again we create a dataset as a copy of the original to not temper with the original data:
```R
data_site_daily_reduced = data_site_daily
```
Now we set the values in our copied dataframe for temperature and dewpoint temperature at the specified indices
in removed_indices to NA
```R
data_site_daily_reduced[removed_indices,]$T = NA
data_site_daily_reduced[removed_indices,]$DP = NA
plot(data_site_daily_reduced$T, pch=19, col="black", cex=.5, xlab="Day", ylab="T [°C]")
```

When we try to simply interpolate with the pointwise linear interpolation, 
you will see that we get a pretty uninformed output:
```R
model = approx(data_site_daily_reduced$T, n=1000)

plot(model$x, model$y, pch=19, col="red", cex=.5, xlab="Day", ylab="T [°C]")
points(data_site_daily_reduced$T, col="black",cex=.5, pch=19)
legend(10,25, legend=c("true data", "modelled data"), col=c("black", "red"), pch=c(19,19))
```

Once again we will create a model to reconstruct our missing data. However, this time we have a whole dataset
of predictors to choose from.  
Since we want to fill a gap in temperature data, we need to find predictors that are well correlated with 
temperature. To figure out which ones are suitable we can make use of the correlation matrix.  
A correlation matrix is a normalized form of a covariance matrix. The values vary between -1 and 1. 
A value of 1 signals a perfect positive, -1 a perfect negative correlation. 0 means that the two variables are not
correlated at all.  


```R
cor = cor(data_site_daily_reduced[,3:18],  use = "complete.obs", method="pearson")
cor

```

As you can see in the output of the code above, all the values on the diagonal are 1. Variables with themselves
are perfectly correlated.   
  
Try to figure out, which variables could be suitable to fill the gaps in our data from the below table.
But beware: DP is the dewpoint temperature, which is calculated from the air temperature. So for the gaps
you will not have that data available!


```R
# Once you have decided on predictors to use, you can go and create your model. 
# 1. Insert your predictors into the model below .
# You can add more than one predictor by concatenating them with a + behind the "~":
# 2. predict the missing data with the predict() function by passing in the model and the reduced dataset
# 3. Plot the true data and your prediction and evaluate the model performance using the summary() function.
#    Did the model perform well? You can try out different predictors and see which ones work best and which
#    do not increase model performance.
#                                       Insert here         Insert here      .....
#                                             |                    |
#                                             V                    V
model = lm(data_site_daily_reduced$T ~ <FIRST VARIABLE> + <SECOND_VARIABLE> + ..., 
           data = data_site_daily_reduced)

#prediction = predict(...)
#plot(data_site_daily$T, , xlab="Day", ylab="T [°C]")
#points(prediction, col="red", pch=19)
#legend(10,25, legend=c("true data", "modelled data"), col=c("black", "red"), pch=c(1,19))

#summary(model)
```

### 2.4: Machine Learning approaches (example Random Forests)
Here we will just take a quick look at a machine learning method which is commonly used for gap filling applications,
Random Forests.
The purpose is that you get an idea of how to implement such a method and at least you have seen it. We will not go
into the details of the actual method.



First we need an extra library for this regression:
```R
install.packages("randomForest") # <-- You can comment this line out once you installed the package
library(randomForest)
```

When applying machine learning or generally models to actual applications, what you have to do is split your data
into two independent sets. One you will use to construct your model on, this is the so called "training" dataset.
The second dataset will be used to test your constructed model on and see how well it performs on data it has 
never seen before. This split is extremely important to maintain, because otherwise you might get an overestimation
of your model performance and your claims can easily be disproved.  
In the previous examples we omitted this procedure because we knew the missing data and could evaluate our model
performance on it, in real life however we do not have the missing data and need to act like a part of the present
datapoints are missing.



From the reduced dataset we remove the rows containing NAN, which is the data we actually do not have.
```R
data_site_daily_reduced_noNA = data_site_daily_reduced[complete.cases(data_site_daily_reduced),] # Remove rows containing NA
```
Additionally the columns containing datetime, line, DP and ST are removed because they are no good predictors or 
are derived from temperature. In the case of surface temperature, we will just act like we don't have it to make
the prediction more interesting.
```R
data_site_daily_reduced_noNA = data_site_daily_reduced_noNA[3:18] # Removing line and ST
data_site_daily_reduced_noNA = data_site_daily_reduced_noNA[,-14] # Removing ST
data_site_daily_reduced_noNA = data_site_daily_reduced_noNA[,-5] # Removing DP
```

Now we will split the remaining dataset into two sets comprising of 70% of the date for training and 30% for testing
We will not use a consecutive sample of the data (e.g. the first x%) but rather a random sample. This is because
consecutive data often time contains a correlation in itself which can lead to biased models. No further details here,
just keep in mind that when training models randomizing the input is an important point (keyword "autocorrelation")

For  this we can use the sample() function. We pass it all available indices of our dataset with "nrow(dataset)". As
input you can use either a vector of values or an integer. If it is an integer like we used here, it is the values 
1 to the integer, so 1 to nrow(data_site_daily_reduced_noNA).
Then we specifiy that we want our sample to be 70% of that data with 0.7*nrow(data_site_daily_reduced_noNA).
With replace = False we specify that we want to remove the indices after sampling them, so we can not pick
an index twice in our sample.
```R
train <- sample(nrow(data_site_daily_reduced_noNA), 0.7*nrow(data_site_daily_reduced_noNA), replace = FALSE)
```


Now we use the sample of indices above to create our training and testing datasets. 
First we use the indices directly to pick the values from the original dataset into our TrainSet
```R
TrainSet <- data_site_daily_reduced_noNA[train,]
```

Then we use the same indices to create our validation dataset, by picking those indices from the original dataset
which are NOT in the train indices array by putting a minus in front of it. That is "exclusive" indexing.
```R
ValidSet <- data_site_daily_reduced_noNA[-train,]
nrow(TrainSet)
nrow(ValidSet)
```

I will only give a very brief intro to random forests here, no need to memorize that. If you are interested,
you can also look the below youtube video for a very good short video on the method.  
https://www.youtube.com/watch?v=v6VJ2RO66Ag
  
Very generally speaking you can say that this algorithm looks at your data and the predictors and it picks
a few of  the predictors, leaving others out.
With this reduced set it trains a model. That means, it tries to find out under which circumstances in the 
predictors, the data has a certain value. 
In random forests, many of those models are trained and compared. Each with different predictors and trained on 
different amounts and points of training data.
After building the model, you can use it to predict unknown values. Therefore, the predictor data for these 
unknown datapoints is fed into each of these models and the combined output from all of them is evaluated as the
final decision.

We will create a Random Forest model with mtry = 6. The mtry keyword defines, how many predictors will be considered
in each model. The argument ntree = 500 means that we will create a total number of 500 models, each containing
a different combination of predictors and data.
```R
rfmodel <- randomForest(T ~ ., data = TrainSet, importance = TRUE, replace=FALSE, mtry=6, ntree=500, type="regression")
rfmodel
```



Similar to how we used the predict() method before for the linear models, we can use it here on our random forest
model. We feed it the model and our validation dataset to test the model performance on unknown data:
```R
predValid <- predict(rfmodel, ValidSet)
```



Lets take a look at how the model output looks compared to the actual data:
```R
plot(ValidSet$T, xlab="Day", ylab="T [°C]")
points(predValid, pch=19, col="red")
legend(110,26, legend=c("true data", "modelled data"), col=c("black", "red"), pch=c(1,19))
```



Now we calculate some metrics to evaluate our model performance: 
```R
metrics = data.frame(
    "RMSE" = sqrt(mean((ValidSet$T - predValid)^2)),
    "R^2" = cor(ValidSet$T, predValid)^2
    )
metrics
```

Our R^2 of more than roughly 0.78 is quite satisfying, considering that we are dealing with daily averaged data in a meteorological context.
A reasonable amount (78%) of the data variance is represented by our model.
The root mean square error of 2.9 is not too bad, but does indicate that specific absolute values are not
exactly predicted by the model.

Finally we can use our model to predict the missing data in our original dataframe:
```R
predgap <- predict(rfmodel, data_site_daily_reduced[removed_indices,])
```

To compare our results, we can plot the reduced data, the true valus and our model output together:
```R
plot(data_site_daily_reduced$T, xlab="Day", cex=0.85, ylab="T [°C]")
points(removed_indices,predgap, pch=19, cex=0.85, col="red")

#points(removed_indices,data_site_daily$T[removed_indices], cex=0.85, pch=19, col="black")
#legend(1,25, legend=c("gap data", "modelled data", "true data"), col=c("black", "red", "black"), pch=c(1,19, 19))
legend(1,25, legend=c("gap data", "modelled data"), col=c("black", "red"), pch=c(1,19))
```

Also look at the plot above with the true data plotted (remove the commenting sign in the cell above).
Now we calculate some metrics to evaluate our model performance: 
```R
metrics = data.frame(
    "RMSE" = sqrt(mean((data_site_daily$T[removed_indices] - predgap)^2, na.rm=TRUE)),
    "R^2" = cor(data_site_daily$T[removed_indices], predgap,  use="complete.obs")^2
    )
metrics
```

As you can see, the R^2 of our gap filled data is not very high. We used the model to predict a gap of data that
is a lot smaller than the validation dataset. It seems that, even though the model did a pretty good job 
predicting the trend of the data on longer timescales, when we look at shorter periods the represented variance decreases
drastically.

Keep in mind that a model is by definition NEVER the actual truth. Its goal is to come as close as possible to the truth
while often times drastically reducing the complexity of the issue. In a real world scenario we would not
know that our final modelled data is not the same as the true data. Therefore all we can do is create and test our models
to the best of our knowledge and be honest about what they are capable of doing and what their shortcomings are!
