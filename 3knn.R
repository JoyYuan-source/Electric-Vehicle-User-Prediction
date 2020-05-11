library(lubridate)
library(dplyr)
library(tidyr)
library(ggplot2)
library(reshape2)
library(class)
library(gmodels)
library(caret)
#library(naivebayes)
dataset<-read.csv('dataset.csv')
#dataset$ID = as.numeric(dataset$ID)
dataset$consumption<-dataset$consumption*4000
dataset[which(dataset$consumption==0),3]<-NA
dataset<-na.omit(dataset)
#dataset <- select(dataset, -c(1))

##dataset<-na.omit(dataset)
dataset$read_date <- as_datetime(dataset$read_date)

df<- dataset %>% mutate(year = year(read_date),month = month(read_date),day = day(read_date),hour = hour(read_date))%>%
  select(-c(2))
df_time <- df %>% mutate(time_flag = case_when(hour %in% c("6","7","8")~"1",
                                               hour %in% c("9","10","11")~"2",
                                               hour %in% c("12","13","14")~"3",
                                               hour %in% c("15","16","17")~"4",
                                               hour %in% c("18","19","20")~"5",
                                               hour %in% c("21","22","23")~"6",
                                               hour %in% c("0","1","2")~"7",
                                               hour %in% c("3","4","5")~"8"))


#group by time_flag
group_ev <- df_time %>% group_by(ID,ev_flag,time_flag,month)%>%summarise(mean = mean(consumption))



#cast data from long to wIDe 
castdf <- dcast(group_ev,ID + month + ev_flag ~ time_flag, value.var = 'mean')

##knn model with train and test set 
castdf<-na.omit(castdf)
castdf$ev_flag<-as.factor(castdf$ev_flag)

#outlier detection 
boxplot(mean ~ time_flag+ev_flag, data=group_ev, main="comsumption across time",
       col='orange',border = 'brown') 

#nor <-function(x) {
#  return ((x - min(x)) / (max(x) - min(x))) }

nor <- function(x) {
  med <- median(x)
  iqr <- IQR(x, na.rm = TRUE)
  return((x - med) / iqr)
}
df_norm <- as.data.frame(lapply(castdf[4:11],nor))


summary(df_norm)


# knn with k-fold cross valIDation
actual_label<-castdf[,3]
cv_pred<- knn.cv(train = df_norm,cl=actual_label,k=18,prob = TRUE)
CrossTable(x=actual_label,y=cv_pred,prop.chisq = FALSE)
cm_cv<-confusionMatrix(cv_pred, actual_label, positive = "1")
cv_accuracy<- cm_cv$overall['Accuracy']



# probability model: assume 80% is threshold 
pred <- castdf %>% mutate(pred = cv_pred)
pred1 <- pred%>%group_by(ID,ev_flag)%>% summarise(actual_count = length(ev_flag))
pred2 <- pred%>%group_by(ID,pred)%>% summarise(pred_count = length(pred))%>%dcast(ID~pred,value.var = 'pred_count')%>%
  mutate(`1` = replace_na(`1`,0))
pred3 <- inner_join(pred1,pred2,by = 'ID')
pred4 <- pred3 %>% mutate(prcnt_Y= `1`/actual_count)%>% mutate(pred_flag = if_else(prcnt_Y >=0.33,'1','0'))


test <- read.csv("EV_Team_Sample_5.csv")
#change date type to date,hour and minutes
test$read_date <- as_datetime(test$read_date)
tt<- test %>% mutate(year = year(read_date),month = month(read_date),day = day(read_date),hour = hour(read_date))%>%
  select(-c(2))
names(tt)[1]='id'
#convert consumption to w/h 
tt$consumption<-tt$consumption*4000
tt[which(tt$consumption==0),3]<-NA
tt<-na.omit(tt)

tt_time <- tt %>% mutate(time_flag = case_when(hour %in% c("6","7","8")~"1",
                                               hour %in% c("9","10","11")~"2",
                                               hour %in% c("12","13","14")~"3",
                                               hour %in% c("15","16","17")~"4",
                                               hour %in% c("18","19","20")~"5",
                                               hour %in% c("21","22","23")~"6",
                                               hour %in% c("0","1","2")~"7",
                                               hour %in% c("3","4","5")~"8"))
#group by time_flag
group_tt <- tt_time %>% group_by(id,time_flag,month)%>%summarise(mean = mean(consumption))

#cast data from long to wide 
casttt <- dcast(group_tt,id + month  ~ time_flag, value.var = 'mean')

##knn model with train and test set 
casttt<-na.omit(casttt)



tt_norm <- as.data.frame(lapply(casttt[3:10],nor))

summary(tt_norm)

# prediction 
tt_predict<-knn(train = df_norm, test = tt_norm, cl= castdf[,3],k=18)


# probability model: assume 40% is threshold 
pred_t <- casttt %>% mutate(pred_sample = tt_predict)
pred1_t <- pred_t%>%group_by(id)%>% summarise(actual_count = length(id))
pred2_t <- pred_t%>%group_by(id,pred_sample)%>% summarise(pred_count = length(pred_sample))%>%dcast(id~pred_sample,value.var = 'pred_count')%>%
  mutate(`1` = replace_na(`1`,0))
pred3_t <- inner_join(pred1_t,pred2_t,by = 'id')
pred3_t <- pred3_t %>% mutate(prcnt_Y= `1`/actual_count)%>% mutate(ev_flag = if_else(prcnt_Y>=0.33,'1','0'))
output <- pred3_t %>% select(c(1,6))
write.csv(output,"output_final.csv")
