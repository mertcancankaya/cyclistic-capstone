# Installing required packages
# tidyverse for data import and wrangling, lubridate for date functions and ggplot for visualization
install.packages("tidyverse")
install.packages("lubridate")
install.packages("ggplot2")

library(tidyverse)  #helps wrangle data
library(lubridate)  #helps wrangle date attributes
library(ggplot2)    #helps visualize data


#====================================================
# STEP 1: COLLECT DATA AND COMBINE INTO A SINGLE FILE
#====================================================

# Combine All 12 Documents into Single Document and Import as Dataset
df <-
  list.files(path = "/Users/admin/Desktop/Cyclistic/", pattern = "*.csv") %>% 
  map_df(~read_csv(.))

# Result of Combining All Data

Rows: 5,779,444
Columns: 13

#======================================================
# STEP 2: CLEAN UP AND ADD DATA TO PREPARE FOR ANALYSIS
#======================================================

# Inspect the new table that has been created
colnames( df)  #List of column names
nrow( df)  #How many rows are in data frame?
dim( df)  #Dimensions of the data frame?
head( df)  #See the first 6 rows of data frame.  Also tail( df)
str( df)  #See list of columns and data types (numeric, character, etc)
summary( df)  #Statistical summary of data. Mainly for numerics


# Reassign to the desired values
 df <-   df %>% 
  mutate(member_casual = recode(member_casual
                           ,"Subscriber" = "member"
                           ,"Customer" = "casual"))

# Check to make sure the proper number of observations were reassigned
table( df$member_casual)

# Add columns that list the date, month, day, and year of each ride
# This will allow us to aggregate ride data for each month, day, or year ... before completing these operations we could only aggregate at the ride level
df$date <- as.Date( df$started_at) #The default format is yyyy-mm-dd
df$month <- format(as.Date( df$date), "%m")
df$day <- format(as.Date( df$date), "%d")
df$year <- format(as.Date( df$date), "%Y")
df$day_of_week <- format(as.Date( df$date), "%A")

# Add a "ride_length" calculation to  df (in seconds)
# https://stat.ethz.ch/R-manual/R-devel/library/base/html/difftime.html
df$ride_length <- difftime( df$ended_at, df$started_at)
# Inspect the structure of the columns
str( df)

# Convert "ride_length" from Factor to numeric so we can run calculations on the data
is.factor( df$ride_length)
df$ride_length <- as.numeric(as.character( df$ride_length))
is.numeric( df$ride_length)
# Remove "bad" data
# The dataframe includes a few hundred entries when bikes were taken out of docks and checked for quality by Divvy or ride_length was negative
# We will create a new version of the dataframe (2) since data is being removed
df2 <- df[!(df$start_station_name == "HQ QR" | df$ride_length<0),]

#Remove NA Values
df2 %>% 
  drop_na(day_of_week, member_casual)

#=====================================
# STEP 3: CONDUCT DESCRIPTIVE ANALYSIS
#=====================================

# Descriptive analysis on ride_length (all figures in seconds)
mean(df2$ride_length,na.rm = TRUE) 
[1] 1160.629
> mean(df2$ride_length,na.rm = TRUE) 
[1] 1160.629
> median(df2$ride_length,na.rm = TRUE) 
[1] 593
> max(df2$ride_length,na.rm = TRUE) 
[1] 2483235
> min(df2$ride_length,na.rm = TRUE)
[1] 0

# Summary
summary(df2$ride_length)
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
      0     339     593    1161    1062 2483235  857836 

# Compare members and casual users
aggregate(df2$ride_length ~ df2$member_casual, FUN = mean)
  df2$member_casual df2$ride_length
          casual      1820.1084
          member       747.0081
aggregate(df2$ride_length ~ df2$member_casual, FUN = median)
  df2$member_casual df2$ride_length
          casual            754
          member            517
aggregate(df2$ride_length ~ df2$member_casual, FUN = max)
  df2$member_casual df2$ride_length
          casual        2483235
          member          93580
aggregate(df2$ride_length ~ df2$member_casual, FUN = min)
  df2$member_casual df2$ride_length
          casual              0
          member              0

# The days of the week are out of order
df2$day_of_week <- ordered(df2$day_of_week, levels=c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"))

# See the average ride time by each day for members vs casual users
aggregate(df2$ride_length ~ df2$member_casual + df2$day_of_week, FUN = mean)
   df2$member_casual df2$day_of_week df2$ride_length
1            casual         Sunday      2153.5467
2            member         Sunday       827.8758
3            casual         Monday      1782.9593
4            member         Monday       708.9199
5            casual        Tuesday      1585.6790
6            member        Tuesday       713.0829
7            casual      Wednesday      1520.0260
8            member      Wednesday       712.1397
9            casual       Thursday      1518.5360
10           member       Thursday       716.4694
11           casual         Friday      1772.5275
12           member         Friday       741.6835
13           casual       Saturday      2123.9553
14           member       Saturday       849.0664

# analyze ridership data by type and weekday
df2 %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>%  
  group_by(member_casual, weekday) %>%  
  summarise(number_of_rides = n()						
            ,average_duration = mean(ride_length)) %>% 	
  arrange(member_casual, weekday)	
   member_casual weekday          number_of_rides   average_duration
   <chr>         <ord>             <int>            <dbl>
 1 casual        Sun              298931            2154.
 2 casual        Mon              214234            1783.
 3 casual        Tue              217161            1586.
 4 casual        Wed              233746            1520.
 5 casual        Thu              250938            1519.
 6 casual        Fri              290811            1773.
 7 casual        Sat              391146            2124.
 8 member        Sun              327649             828.
 9 member        Mon              412964             709.
10 member        Tue              475730             713.
11 member        Wed              492794             712.
12 member        Thu              485628             716.
13 member        Fri              440473             742.
14 member        Sat              389296             849.


#======================
# STEP 4: VISUALIZATION
#======================
# Let's visualize by Number of Rides by Days and Member Type
df2 %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>% 
  group_by(member_casual, weekday) %>% 
  summarise(number_of_rides = n(), average_duration = mean(ride_length)) %>% 
  arrange(member_casual, weekday)  %>% 
  ggplot(aes(x = weekday, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(x = "Days", y = "Number of Rides", title = "Number of Rides by Days and Member Type")

# Let's create a visualization for average duration
df2 %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>% 
  group_by(member_casual, weekday) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>% 
  arrange(member_casual, weekday)  %>% 
  ggplot(aes(x = weekday, y = average_duration, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(x = "Days", y = "Average Duration", title = "Average Duration of Rides by Days and Member Type")

# Let's create a visualization for Number of Rides by Month and Member Type
df2 %>%
  mutate(Month = month(started_at, label = TRUE)) %>% 
  group_by(member_casual, Month) %>% 
  summarise(number_of_rides = n(), average_duration = mean(ride_length)) %>% 
  arrange(member_casual, Month) %>%
  ggplot(aes(x = Month, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(x = "Month", y = "Number of Rides", title = "Number of Rides by Month and Member Type")


# Let's visualize by Average Duration of Rides by Month and Member Type
df2 %>%
  mutate(Month = month(started_at, label = TRUE)) %>% 
  group_by(member_casual, Month) %>% 
  summarise(number_of_rides = n(), average_duration = mean(ride_length)) %>% 
  arrange(member_casual, Month) %>%
  ggplot(aes(x = Month, y = average_duration, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(x = "Month", y = "Average Duration", title = "Average Duration of Rides by Month and Member Type")


# Let's visualize by Number of Rides by Member Type and Rideable Type
df2 %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>% 
  group_by(member_casual, rideable_type) %>% 
  summarise(number_of_rides = n(), average_duration = mean(ride_length)) %>% 
  arrange(member_casual, rideable_type)  %>% 
  ggplot(aes(x = rideable_type, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(x = "Rideable Type", y = "Number of Rides", title = "Number of Rides by Member Type and Rideable Type")


# Let's visualize by Number of Rides by Rideable Type and Month
df2 %>% 
  mutate(Month = month(started_at, label = TRUE)) %>% 
  group_by(member_casual, rideable_type, Month) %>% 
  summarise(number_of_rides = n(), average_duration = mean(ride_length)) %>% 
  arrange(member_casual, rideable_type)  %>% 
  ggplot(aes(x = Month, y = number_of_rides, fill = rideable_type)) +
  geom_col(position = "dodge") +
  labs(x = "Month", y = "Number of Rides", title = "Number of Rides by Rideable Type and Month")

