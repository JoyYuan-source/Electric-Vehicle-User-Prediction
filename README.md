# Electric-Vehicle-User-Prediction
 To help Oncor Electric Delivery Company LLC  meet customers’ need in real time,  we identified EV users at the first step, and then analyzed their electricity using pattern, finally applied models to whole customer segment to identify EV users for capacity planning. 

# Overview 
Benefits such as lower fuel costs, environmentally friendly driving, the growing number of charging stations are encouraging more drivers to drive the electric vehicles. As the largest electricity delivery firm in Texas, along with the Smart Meters that can easily track the electricity usage of EVs, Oncor is helping change and drive the demand for EVs of residential customers. Open to various analytics tools, Oncor provides customers with EV Model Comparison Tool , PHEV Model Comparison Tool and Air Quality Impact Tool to deliver the EVs benefit for residents. At the same time, the project also wants to identify the customers’ electricity usage pattern and forecast their demand change. Therefore, Oncor could adjust the electricity grid and distribution system to meet customers’ need in real time and improve electricity delivery efficiency by reducing time costs.

# Data and Usage 
Advanced Metering Infrastructure (AMI), aka Smart Meters, send 15 consumption (kW) and voltage data back to Oncor at 15-minute intervals.  We believe we have enough data to identify which premise locations may have EV’s based on historical and current usage patterns.  We want to analyze AMI data to identify the general locations of EV’s (or premises that exhibit EV like behavior) for capacity planning and growth purposes. We would like to develop a model which will allow us to periodically analyze all premises for the probability of electric vehicle location and identify areas where growth is most likely. 

# Conceptual Design 
![image](https://user-images.githubusercontent.com/65084653/81610545-55653280-939f-11ea-806b-c48e19ee17ec.png)

# NILM Model 
Nonintrusive Load Monitoring (NILM) is existing technique which helps us monitor electricity consumption effectively and costly. NILM is a promising approach to obtain estimates of the electrical power consumption of individual appliances from aggregate measurements of voltage and/or current in the distribution system. 

In the real world, EV customers always charge their electric vehicles with static and high electricity power for several hours during late night. Therefore we assume that ev signals may show like square wave overlapped by other electric devices signal spikes. By comparing daily power signals between ev customers above and non-ev customers below, we can easily find the possible ev signals in the black box, which have long and relatively static duration power in late night and early morning, while other devices signals show as lower spikes most of the time and may show as extremely high spikes ocassionally. We assumed that the high spikes may belong to high power appliances such as air conditioner, washer, dryer or so on.   

![image](https://user-images.githubusercontent.com/65084653/81611256-534fa380-93a0-11ea-94bb-2835a83e9f31.png)

## Steps 
The general goal we need to achieve is to create an estimated ev signals function and put our daily aggregate time series consumption data into it. Therefore we can separate ev signals from aggregate consumption data.    
1. Within the function, the first thing we need to do is to remove the minimum signals , namely residual , that are apparently not ev signals.   
2. Since most of the ev charging signals are higher than 3000 watt, we decided to remove all the signals lower than 3000 watt.  
3. After removal and thresholding, we explore the remaining signals segment by segment to discuss the electricity usage duration and so on and extract the  square wave of ev signals.   
4. We then filter out the segments shorter than 3 hours or longer than 15 hours by analyzing the length of x axis.   
5. After we filter out the too long or too short segment, we still have something to deal with. Some segments remains some high spikes probably belong to other high power electricity appliances such as air conditioner, dryer, washer or so on. After the observation, we find that electric vehicle charging power always appear within the points of 80% of our segment width. Therefore, we decided to choose the start points and end points that are 80% of segment width, link them together to form a square wave same as electric vehicle charging signals pattern and set the points’ height as effective height. And Then we filter out the points that are higher than effective height. Finally, we can successfully extract our electric vehicle charging signals in rectangular-like shape.  

![image](https://user-images.githubusercontent.com/65084653/81611632-00c2b700-93a1-11ea-98e8-82cd6d3bb5c1.png)

# KNN Model 
As we know that NILM model is a non-training model based on understandable human rules: For example, electric vehicle recharging power should be higher than 3000 watt per hour, and the recharging duration greater than 2 hours. We are also considering that whether NILM model produces similar or better outcome than machine learning method, which needs enough data to train.  
Why we are thinking about using a totally different approach to solve this prediction problem?  
Firstly, we know that EV users used less electricity in the morning and used more electricity in the night. We arranged data into different time slots to let machine learn the comsumption differnece between EV users and non-EV users.
Secondly, we have enough data to be the training set. 

# Output and Conclusion
Both Models have similar accuracy, higher than 90%.
NILM model does not need to train and it is easier to revise on different situations. KNN models need training and need to be updated often.  Since both models have similar accuracy, we prefer NILM model because it does not need data to train.  
 
We can improve NILM by doing more market research and revise thresholds for different EV users, ford example: Research electric car types and the recharge power and set different rules for common electric car types. We can improve KNN by including more data on training set and training model more often.  
 
In conclusion, NILM model can be easily revised to predict electric vehicle usage time and estimate recharging power based on human understanding. In addition, Oncor can use our prediction to distribute electricity more wisely and use our prediction to target electric vehicle users and offer them extracting electricity plan.  
