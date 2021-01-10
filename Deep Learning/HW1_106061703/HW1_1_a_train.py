# -*- coding: utf-8 -*-
"""
Created on Fri Nov  2 13:34:10 2018

@author: 藍國瑞
"""

import csv
import numpy as np
import random
import matplotlib.pyplot as plt



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

##data_total_shuffle=np.random.shuffle(data_total)
data_shuffle=np.take(data_total,np.random.permutation(data_total.shape[0]),axis=0)
##data_shuffle=preprocessing.minmax_scale(data_shuffle)


train_set=data_shuffle[0:576,:]
train_feature=train_set[:,0:15]
train_label=train_set[:,15]

test_set=data_shuffle[576:768,:]
test_feature=test_set[:,0:15]
test_label=test_set[:,15]







    
########## regression result with the training labels ##########

epoch=2000
learning_rate = 0.000001
total_loss=0


#weights1 =( np.random.uniform(low=-0.5,high=0.5,size=(train_feature.shape[1],units_of_the_hidden_units)) )
#weights2 = np.random.uniform(low=-0.5,high=0.5,size=(units_of_the_hidden_units,1))
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
        
        #layer1=sigmoid_activation(np.dot(batchX,weights1))
        #layer2=sigmoid_activation(np.dot(layer1,weights2))
        #output=np.dot(layer1,weights3)
        
        
        print("output=",output)
        error=output-oneD_row_column(batchY)
        print("error=\n",error)
        loss=np.sum(error**2)
        total_loss+=loss
        epochLoss.append(loss)
        
        d_weights2=np.dot(layer1.T, ( 2*error  )  )
        d_weights1=np.dot(batchX.T,  (np.dot(2*error*1 , weights2.T) *sigmoid_derivative(layer1)))
       
        #d_weights3 = np.dot(layer2.T, (2*error ))
        #d_weights2 = np.dot(layer1.T, (np.dot(2*error ,weights3.T) * sigmoid_derivative(layer2)))
        #d_weights1 = np.dot(batchX.T, np.dot (np.dot(2*error ,weights3.T)* sigmoid_derivative(layer2), weights2.T)*sigmoid_derivative(layer1))

        
        
        
        weights1 =weights1-learning_rate *d_weights1
        weights2 =weights2-learning_rate *d_weights2
        
        bias_1=bias_1-learning_rate * np.dot(bias_g.T,(np.dot(2*error*1 , weights2.T) *sigmoid_derivative(layer1)))
        bias_2=bias_2-learning_rate *np.dot(bias_g.T ,( 2*error  ))
        
        #weights3 =weights2-learning_rate *d_weights3
        
    train_RMS_i=np.sqrt(total_loss/train_feature.shape[0])
    print("epoch=",i)
    print("train_RMS=",train_RMS_i)  
    train_RMS_record.append(train_RMS_i)
    lossHistory.append(np.average(epochLoss))



train_RMS=np.sum(train_RMS_record)/epoch
print("train_RMS_overall",train_RMS)

 

fig = plt.figure()
plt.plot(np.arange(0, epoch), lossHistory)
fig.suptitle("Training curve")
plt.xlabel("Epoch #")
plt.ylabel("Loss")
plt.show()


 #d_weights1 = np.dot(self.input.T,  (np.dot(2*(self.y - self.output) * sigmoid_derivative(self.output), self.weights2.T) * sigmoid_derivative(self.layer1)))

########### test_RMS ##########

 
layer1_test=sigmoid_activation(np.dot(test_feature,weights1)+bias_1)
output_test=np.dot(layer1_test,weights2)+bias_2


error_test=output_test-oneD_row_column(test_label)
test_RMS=np.sqrt((np.sum(error_test ** 2)/test_label.shape[0]))
print("test_RMS=",test_RMS)


#output_test_normalize=preprocessing.minmax_scale(output_test)

fig1 = plt.figure()
plt.plot(np.arange(0, output_test.shape[0]), output_test)
fig.suptitle("prediction for test data")
plt.xlabel("Epoch #")
plt.ylabel("Heating Load")
plt.show()



############### train_RMS ###############


#train_label_scale=preprocessing.scale(train_label)

layer1_train=sigmoid_activation(np.dot(train_feature,weights1)+bias_1)
output_train=np.dot(layer1_train,weights2)+bias_2



error_train=output_train-oneD_row_column(train_label)

train_RMS=np.sqrt((np.sum(error_train ** 2)/train_label.shape[0]))
print("train_RMS=",train_RMS)


#output_train_normalize=preprocessing.minmax_scale(output_train)


fig2 = plt.figure()
plt.plot(np.arange(0, output_train.shape[0]), output_train)
fig.suptitle("prediction for train data")
plt.xlabel("Epoch #")
plt.ylabel("Heating Load")
plt.show()






