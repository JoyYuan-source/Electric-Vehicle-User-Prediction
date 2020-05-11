library(lubridate)
library(ggplot2)
library(dplyr)

## List filenames to be merged. 
filenames <- list.files(path="C:/Users/yuan5/OneDrive/Documents/smu files/ev data/files",pattern="csv")

## Print filenames to be merged
print(filenames)

## Full path to csv filenames
fullpath=file.path("C:/Users/yuan5/OneDrive/Documents/smu files/ev data/files",filenames)

## Print Full Path to the files
print(fullpath)

## Merge listed files from the path above
data <- do.call("rbind",lapply(fullpath,FUN=function(files){ read.csv(files)}))

data[which(is.na(data$consumption)),3] <- 0
data$read_date <- as_datetime(data$read_date)
data$id <- data$ï..esi_id

#slice the data 
#data <- data[which(data$ev_flag=="N"),][1:200000,]


#extract all the years and months
data <- data %>%
  mutate(year=year(data$read_date),month=month(data$read_date))

y_m=data%>%
  select(year,month)%>%
  distinct()

#set the input and coefficient in this model
#===========================================
interval=15
width_Percent=0.8
# We suppose that the height of EV segment should be higher than EVAMP
EVAMP=3500
# We suppose that appliance which power is below 3000W must not be EV 
Threshold_value=3000
# We believe that EV charging duration must be longer than 180 minutes, and the maximum is 900 minutes
min_duration = 180
max_duration = 900
#==========================================


#group the data by year and month and then get the result
result=group_by(data,id,year,month)%>% do(as.data.frame(estEV(.)))
print(result,n=nrow(result))

newresult <- result[,c(1,5)]

library(data.table)
nresult <- dcast(newresult, id ~ paste0("Number.of.Signal", rowid(id)), value.var = "Number.of.Signal")

nresult <- nresult %>%
  mutate(EV_flag=1)

nresult[is.na(nresult)] <- 0

nresult$EV_flag <- as.factor(nresult$EV_flag)

library(randomForest)
model.rf<-randomForest(nresult$EV_flag~.,data = nresult,ntree=4,mtry=2,importance=T)
model.rf










