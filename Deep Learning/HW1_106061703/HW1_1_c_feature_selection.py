# -*- coding: utf-8 -*-
"""
Created on Mon Nov  5 12:52:19 2018

@author: 藍國瑞
"""

import csv
import numpy as np
import scipy.stats
from itertools import combinations
import argparse
from keras.models import Sequential
from keras.layers import Dense
import random
import matplotlib.pyplot as plt
from sklearn import preprocessing



data=[];
data_glazing_area=[]
data_orientation=[]
data_glazing_area_distribution=[]
label=[];


def oneD_row_column(b):
    number_of_data=b.shape[0]
    output=np.zeros((number_of_data,1),dtype=np.float64)
    for i in range(number_of_data):
        output[i][0]=b[i]
    return output



def sigmoid_activation(x):
	# compute and return the sigmoid activation value for a
	return 1.0 / (1 + np.exp(-x))
 
    
def sigmoid_derivative(x):
    return x * (1.0 - x)

def next_batch(X, y, batchSize):
    

    list=[]
    for i in np.arange(0, X.shape[0], batchSize):

		# yield a tuple of the current batched data and labels
	     list.append((X[i:i + batchSize], y[i:i + batchSize]))
    return list

def next_batch_feature(X, batchSize):
    

    list=[]
    for i in np.arange(0, X.shape[0], batchSize):

		# yield a tuple of the current batched data and labels
	     list.append(X[i:i + batchSize])
    return list





with open('energy_efficiency_data.csv', newline='') as f:
    
    next(csv.reader(f))

    for row in csv.reader(f):
        data.append(row[0:5]) 
        data_orientation.append(row[5]) ###one hot
        data_glazing_area.append(row[6])
        data_glazing_area_distribution.append(row[7]) ###one hot
        label.append(row[8])




number_of_data=np.shape(data)[0]


data=np.array(data, dtype=np.float64)
data_glazing_area=np.array(data_glazing_area, dtype=np.float64)
data_orientation=np.array(data_orientation, dtype=np.float64)
data_glazing_area_distribution = np.array(data_glazing_area_distribution,dtype=np.float64) 
label=np.array(label,dtype=np.float64)
########################################################
data_orientation_onehot=np.zeros((number_of_data,4),dtype=int)

data_glazing_area_distribution_onehot=np.zeros((number_of_data,5),dtype=int)

###### orientation_onehot ########
for i in range(number_of_data):
    if data_orientation[i]==2:
        data_orientation_onehot[i]=[0,0,0,1] #north
        
    elif data_orientation[i]==3:
        data_orientation_onehot[i]=[0,0,1,0] #east
        
    elif data_orientation[i]==4:
        data_orientation_onehot[i]=[0,1,0,0] #south
        
    elif  data_orientation[i]==5:
        data_orientation_onehot[i]=[1,0,0,0] #west  


###### glazing_area_distribution ##########

for i in range(number_of_data):
    
    if   data_glazing_area_distribution[i]==1:
        data_glazing_area_distribution_onehot[i]=[0,0,0,0,1] #uniform
        
    elif data_glazing_area_distribution[i]==2:
        data_glazing_area_distribution_onehot[i]=[0,0,0,1,0] #north
        
    elif data_glazing_area_distribution[i]==3:
        data_glazing_area_distribution_onehot[i]=[0,0,1,0,0] #east
        
    elif data_glazing_area_distribution[i]==4:
        data_glazing_area_distribution_onehot[i]=[0,1,0,0,0] #south
        
    elif  data_glazing_area_distribution[i]==5:
        data_glazing_area_distribution_onehot[i]=[1,0,0,0,0] #west 

##########################################

data_glazing_area_transpose=oneD_row_column(data_glazing_area)
##########################################

label_transpose=oneD_row_column(label)
    

    
########################################### 

data_total=np.c_[data,data_orientation_onehot,data_glazing_area_transpose,data_glazing_area_distribution_onehot,label_transpose]
#### assume there are five features influence the energy load significantly ####






train_RMS_ALL=[]
test_RMS_ALL=[]

number_of_significant_feature=7




for choice in list(combinations(range(8), number_of_significant_feature)):
    print("choice=",choice)
    ########### initialize the selected feature ############
    select_0=np.zeros((data.shape[0],1),dtype=np.float64)
    select_1=np.zeros((data.shape[0],1),dtype=np.float64)
    select_2=np.zeros((data.shape[0],1),dtype=np.float64)
    select_3=np.zeros((data.shape[0],1),dtype=np.float64)
    select_4=np.zeros((data.shape[0],1),dtype=np.float64)
    select_5=np.zeros((data.shape[0],4),dtype=np.float64)
    select_6=np.zeros((data.shape[0],1),dtype=np.float64)
    select_7=np.zeros((data.shape[0],5),dtype=np.float64)

    data_combination=np.zeros((data.shape[0],15),dtype=np.float64)
    #######################################################
    
    for i in choice:
        print("i=",i)
        if i==5: ####orientation one hot encoding
            select_5=data_total[:,5:9]
            #data_combination=np.c_[select_1]
        elif i==7: ####glazing area distribution
            select_7=data_total[:,10:15]
          
        elif i==0:
            select_0=oneD_row_column(data_total[:,0])
            
        elif i==1:
            select_1=oneD_row_column(data_total[:,1])
            
        elif i==2:
            select_2=oneD_row_column(data_total[:,2])
            
        elif i==3:
            select_3=oneD_row_column(data_total[:,3])
            
        elif i==4:
            select_4=oneD_row_column(data_total[:,4])
            
        elif i==6:
            select_6=oneD_row_column(data_total[:,6])
            
    data_combination=np.c_[select_0,select_1,select_2,select_3,select_4,select_5,select_6,select_7,label_transpose]
    

    data_shuffle=np.take(data_combination,np.random.permutation(data_total.shape[0]),axis=0)

    train_set=data_shuffle[0:576,:]
    train_feature=train_set[:,0:15]
    train_label=train_set[:,15]

    test_set=data_shuffle[576:768,:]
    test_feature=test_set[:,0:15]
    test_label=test_set[:,15]
    
    
    ################# regression model ###############
    
    epoch=500
    units_of_the_hidden_units=10
    learning_rate = 0.000001
    total_loss=0


    weights1=np.random.rand(15,12)*0.1-0.05
    weights2=np.random.rand(12,1)*1-0.5
    bias_1=np.zeros((1,12))
    bias_2=np.zeros((1,1))
    bias_g=np.ones((16,1))
    
    
    
    lossHistory = []
    train_RMS_i=[]
    train_RMS_record=[] 

    for i in range(epoch):
        epochLoss=[]
    
        for (batchX,batchY) in next_batch(train_feature,train_label,16):
            print("weights1=\n",weights1)
            print("weights2=\n",weights2)
        
            layer1=sigmoid_activation(np.dot(batchX,weights1)+bias_1)
            output=np.dot(layer1,weights2)+bias_2
            
            print("output=",output)
            error=output-oneD_row_column(batchY)
            print("error=\n",error)
            loss=np.sum(error**2)
            total_loss+=loss
            epochLoss.append(loss)
        
            gradient_weights2=np.dot(layer1.T, ( 2*error  )  )
            
            gradient_weights1=np.dot(batchX.T,  (np.dot(2*error*1 , weights2.T) *sigmoid_derivative(layer1)))
        
            weights1 =weights1-learning_rate *gradient_weights1
            weights2 =weights2-learning_rate *gradient_weights2
            
            
            bias_1=bias_1-learning_rate * np.dot(bias_g.T,(np.dot(2*error*1 , weights2.T) *sigmoid_derivative(layer1)))
            bias_2=bias_2-learning_rate *np.dot(bias_g.T ,( 2*error  ))
            
            
    ############# finish training ##############
    ############# train_RMS ##############
    
    
    layer1_train=sigmoid_activation(np.dot(train_feature,weights1)+bias_1)
    output_train=np.dot(layer1_train,weights2)+bias_2
    error_train=output_train-oneD_row_column(train_label)

    train_RMS=np.sqrt((np.sum(error_train ** 2)/train_label.shape[0]))
    
    print("train_RMS=",train_RMS)
    train_RMS_ALL.append(train_RMS)
    #output_train_scaled=preprocessing.scale(output_train)

        
    
    ########### test_RMS ##########
    layer1_test=sigmoid_activation(np.dot(test_feature,weights1)+bias_1)
    output_test=np.dot(layer1_test,weights2)+bias_2
    error_test=output_test-oneD_row_column(test_label)

    test_RMS=np.sqrt((np.sum(error_test ** 2)/test_label.shape[0]))
    
    print("test_RMS=",test_RMS)
    test_RMS_ALL.append(test_RMS)
     
















