# -*- coding: utf-8 -*-
"""
Created on Sun Jun 24 09:28:28 2018

@author: 藍國瑞
"""

################################1.1.1###################################

import csv
import numpy as np
import pydotplus
from sklearn import tree
from IPython.display import Image  
from IPython.display import display
from sklearn.metrics import mean_squared_error
from sklearn.metrics import r2_score



A=[]
B=[]
train=[]
response=[]

AA=[]
BB=[]
test=[]
response_test=[]

fearure=[]
feature=['age','fnlwgt','education_num','sex','capital_gain','capital_loss','income'] 

#### train ###
with open('census_income_train.csv', newline='') as f:
    next(csv.reader(f))
    for row in csv.reader(f):
        if row[3]==' Male':
            row[3]='1'
        elif row[3]==' Female':
            row[3]='0'
        A.append(row[0:6])
        
        
        if row[7]==' <=50K':
            row[7]='1'
        
        elif row[7]==' >50K':
            row[7]='0'
        B.append(row[7])
        

        response.append(row[6])
        
        
  
A=np.array(A,dtype=np.float)
B=np.array(B,dtype=np.float)
A=np.transpose(A)

train=np.vstack((A,B))
train=np.transpose(train)

response=np.array(response,dtype=np.float)  

### test ###
with open('census_income_test.csv', newline='') as f:
    next(csv.reader(f))
    for row in csv.reader(f):
        if row[3]==' Male':
            row[3]='1'
        elif row[3]==' Female':
            row[3]='0'
        AA.append(row[0:6])
        
        
        if row[7]==' <=50K.':
            row[7]='1'
        
        elif row[7]==' >50K.':
            row[7]='0'
        BB.append(row[7])
        

        response_test.append(row[6])
        
        
  
AA=np.array(AA,dtype=np.float)
BB=np.array(BB,dtype=np.float)
AA=np.transpose(AA)

test=np.vstack((AA,BB))
test=np.transpose(test)

response_test=np.array(response_test,dtype=np.float)  



######################## regression tree(5,2,2) #############################

reg_1 = tree.DecisionTreeRegressor(max_depth=5,min_samples_split=2,min_samples_leaf=2)
result=reg_1.fit(train,response)


dot_data = tree.export_graphviz(result,out_file = '522.dot',
                             feature_names=feature,  
                             class_names=None,  
                             filled=True, rounded=True,  
                             special_characters=True) 
graph = pydotplus.graphviz.graph_from_dot_file("522.dot")

pic_1=Image(graph.create_png(),width=900,height=400)
display(pic_1)

### train mse ###
prediction_train=reg_1.predict(train)
E_train=response-prediction_train
rss_train=np.dot(E_train, np.transpose(E_train))
mse_train=(rss_train) / 32561

### test mse ###
prediction_test=reg_1.predict(test)
mse_test=mean_squared_error(response_test , prediction_test)


### R squared ###
response_mean=np.mean(response)
response_mean_bias=response-response_mean
tss = np.dot(np.transpose(response_mean_bias),response_mean_bias)

R_squared=1-(rss_train/tss)



###################### regression tree(10,2,2) ###########################

reg_2 = tree.DecisionTreeRegressor(max_depth=10,min_samples_split=2,min_samples_leaf=2)
result2=reg_2.fit(train,response)


dot_data = tree.export_graphviz(result2,out_file = '1022.dot',
                             feature_names=feature,  
                             class_names=None,  
                             filled=True, rounded=True,  
                             special_characters=True) 
graph = pydotplus.graphviz.graph_from_dot_file("1022.dot")


pic_2=Image(graph.create_png(),width=900,height=400)

display(pic_2)

### train mse ###
prediction_train_2=reg_2.predict(train)
mse_train_2=mean_squared_error(prediction_train_2,response)

###test mse ###
prediction_test_2=reg_2.predict(test)
mse_test_2=mean_squared_error(prediction_test_2,response_test)

### R squared ###
R_squared_2=r2_score(response, prediction_train_2)



######################## regression tree(10,4,4) ###############################

reg_3 = tree.DecisionTreeRegressor(max_depth=10,min_samples_split=4,min_samples_leaf=4)
result3=reg_3.fit(train,response)


dot_data = tree.export_graphviz(result3,out_file = '1044.dot',
                             feature_names=feature,  
                             class_names=None,  
                             filled=True, rounded=True,  
                             special_characters=True) 
graph = pydotplus.graphviz.graph_from_dot_file("1044.dot")


pic_3=Image(graph.create_png(),width=900,height=400)

display(pic_3)

### train mse ###
prediction_train_3=reg_3.predict(train)
mse_train_3=mean_squared_error(prediction_train_3,response)

###test mse ###
prediction_test_3=reg_3.predict(test)
mse_test_3=mean_squared_error(prediction_test_3,response_test)

### R squared ###
R_squared_3=r2_score(response, prediction_train_3)

######## tabulate ########

train_mse=np.array([mse_train,mse_train_2,mse_train_3])
test_mse=np.array([mse_test,mse_test_2,mse_test_3])
R_SQUARED=np.array([R_squared,R_squared_2,R_squared_3])


################################1.1.2####################################


import csv
import numpy as np
import matplotlib.pyplot as plt
from sklearn import tree


A=[]
B=[]
train=[]
response=[]


fearure=[]
feature=['age','fnlwgt','education_num','sex','capital_gain','capital_loss','income'] 

#### train ###
with open('census_income_train.csv', newline='') as f:
    next(csv.reader(f))
    for row in csv.reader(f):
        if row[3]==' Male':
            row[3]='1'
        elif row[3]==' Female':
            row[3]='0'
        A.append(row[0:6])
        
        
        if row[7]==' <=50K':
            row[7]='1'
        
        elif row[7]==' >50K':
            row[7]='0'
        B.append(row[7])
        

        response.append(row[6])
        
        
  
A=np.array(A,dtype=np.float)
B=np.array(B,dtype=np.float)
A=np.transpose(A)

train=np.vstack((A,B))
train=np.transpose(train)

response=np.array(response,dtype=np.float)  



### 3-fold cross validation ###

### 1st part:validation set , remaining parts:training set ###
train_1=train[0:10853]
train_23=train[10853:32561]

response_1=response[0:10853]
response_23=response[10853:32561]

mse_1=[]
d=[5,10,15,20,25]
for i in range(5):
    reg_1 = tree.DecisionTreeRegressor(max_depth= d[i])
    result_1=reg_1.fit(train_23,response_23)

    prediction_1=result_1.predict(train_1)
    E_1=response_1-prediction_1
    mse_1.append((np.dot(E_1,np.transpose(E_1))) / 10853)
    


### 2nd part:validation set , remaining parts:training set ###
train_2=train[10853:21707]

train_13=np.vstack((train[0:10853],train[21707:32561]))

response_2=response[10853:21707]
response_13=np.concatenate((response[0:10853],response[21707:32561]),axis=0)

mse_2=[]
d=[5,10,15,20,25]
for i in range(5):
    reg_2 = tree.DecisionTreeRegressor(max_depth=d[i])
    result_2=reg_2.fit(train_13,response_13)
    
    prediction_2=result_2.predict(train_2)
    E_2=response_2-prediction_2
    mse_2.append((np.dot(E_2,np.transpose(E_2))) / 10854)


### 3rd part:validation set , remaining parts:training set ###
train_3=train[21707:32561]
train_12=train[0:21707]

response_3=response[21707:32561]
response_12=response[0:21707]

mse_3=[]
d=[5,10,15,20,25]
for i in range(5):
    reg_3 = tree.DecisionTreeRegressor(max_depth=d[i])
    result_3=reg_3.fit(train_12,response_12)

    prediction_3=result_3.predict(train_3)
    E_3=response_3-prediction_3
    mse_3.append((np.dot(E_3,np.transpose(E_3))) / 10854)

### overall MSE ###
mse_1=np.array(mse_1)    
mse_2=np.array(mse_2)    
mse_3=np.array(mse_3)    
        
mse_overall=(mse_1*10853+mse_2*10854+mse_3*10854)/32561

### figure ###
plt.figure()
plt.plot(d, mse_overall, color="cornflowerblue", linewidth=2)
plt.xlabel("max_depth")
plt.ylabel("CV error")
plt.legend()
plt.show()

################################1.2#######################################


import csv
import numpy as np
import matplotlib.pyplot as plt
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import BaggingRegressor, RandomForestRegressor,AdaBoostRegressor
from sklearn.metrics import mean_squared_error



A=[]
B=[]
train=[]
response=[]

AA=[]
BB=[]
test=[]
response_test=[]

fearure=[]
feature=['age','fnlwgt','education_num','sex','capital_gain','capital_loss','income'] 

#### train ###
with open('census_income_train.csv', newline='') as f:
    next(csv.reader(f))
    for row in csv.reader(f):
        if row[3]==' Male':
            row[3]='1'
        elif row[3]==' Female':
            row[3]='0'
        A.append(row[0:6])
        
        
        if row[7]==' <=50K':
            row[7]='1'
        
        elif row[7]==' >50K':
            row[7]='0'
        B.append(row[7])
        

        response.append(row[6])
        
        
  
A=np.array(A,dtype=np.float)
B=np.array(B,dtype=np.float)
A=np.transpose(A)

train=np.vstack((A,B))
train=np.transpose(train)

response=np.array(response,dtype=np.float)  

### test ###
with open('census_income_test.csv', newline='') as f:
    next(csv.reader(f))
    for row in csv.reader(f):
        if row[3]==' Male':
            row[3]='1'
        elif row[3]==' Female':
            row[3]='0'
        AA.append(row[0:6])
        
        
        if row[7]==' <=50K.':
            row[7]='1'
        
        elif row[7]==' >50K.':
            row[7]='0'
        BB.append(row[7])
        

        response_test.append(row[6])
        
        
  
AA=np.array(AA,dtype=np.float)
BB=np.array(BB,dtype=np.float)
AA=np.transpose(AA)

test=np.vstack((AA,BB))
test=np.transpose(test)

response_test=np.array(response_test,dtype=np.float)  


### bagging ###
mse_bagging=[]
number_of_tree=[20,40,60,80,100]
for i in range(0,5):
    reg_bagging=BaggingRegressor(n_estimators=number_of_tree[i])
    
    result_bagging=reg_bagging.fit(train,response)
    prediction_bagging=result_bagging.predict(test)
    mse_bagging.append(mean_squared_error(response_test,prediction_bagging))

### randomforest ###
mse_random=[]
number_of_tree=[20,40,60,80,100]
for i in range(0,5):
    reg_random=RandomForestRegressor(n_estimators=number_of_tree[i],max_features=3)
    result_random=reg_random.fit(train,response)
    prediction_random=result_random.predict(test)
    mse_random.append(mean_squared_error(response_test,prediction_random))
  
### boosing ###
mse_boosting=[]
number_of_tree=[20,40,60,80,100]
for i in range(0,5):
    dtree=DecisionTreeRegressor(max_depth=1)
    reg_boosting=AdaBoostRegressor(dtree,learning_rate=0.01,n_estimators=number_of_tree[i])
    result_boosting=reg_boosting.fit(train,response)
    prediction_boosting=result_boosting.predict(test)
    mse_boosting.append(mean_squared_error(response_test,prediction_boosting))


plt.figure()
plt.plot(number_of_tree, mse_bagging, color="cornflowerblue", label="Bagging", linewidth=2)
plt.plot(number_of_tree, mse_random, color="yellowgreen", label="Random Forests", linewidth=2)
plt.plot(number_of_tree, mse_boosting, color="red", label="Boosting", linewidth=2)
plt.xlabel("number_of_tree")
plt.ylabel("test_mse")
plt.legend()
plt.show()

