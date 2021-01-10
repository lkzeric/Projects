# -*- coding: utf-8 -*-
"""
Created on Fri Apr 13 23:32:26 2018

@author: 藍國瑞
"""

import csv
import numpy as np
from sklearn.metrics import roc_curve, auc
import matplotlib.pyplot as plt
from sklearn.metrics import confusion_matrix
label=[]
train=[]
test=[]




with open('train_MNIST_logistic_regression.csv', newline='') as f:
    next(csv.reader(f))

    for row in csv.reader(f):
        train.append(row[1:]) 
        label.append(row[0])

with open('test_MNIST_logistic_regression.csv', newline='') as f:
  

    for row in csv.reader(f):
        test.append(row)
        
        
        
test_label=np.zeros(shape=(1310,1))
test_real=[]
with open('test_label.csv', newline='') as f:
    
     for row in csv.reader(f):
         test_real.append(row)
         
test_real=np.array(test_real)
for i in range(1310):
    test_label[i][0]=test_real[i][1]
         
       

        
test=np.array(test,dtype=np.float64)
train=np.array(train,dtype=np.float64)
label=np.array(label,dtype=np.float64)
label_t =np.transpose(label)

'''
train_part1 = train[:6500]
label_part1 = label[:6500]

train_confusion = train[6500:7000]
label_confusion = label[6500:7000]
'''

for n,i in enumerate(label):
    if i==2:
        label[n]=1
    
for n,i in enumerate(test_label):
    if i==2:
        test_label[n]=1

test_label_flatten = test_label.ravel()


lr= 0.05
number_of_iteration = 750
class logisticregression:
    def gradient_descent(self , train , label):
        beta = np.ones((np.shape(train)[1], 1))
        for i in range(number_of_iteration):
            beta = beta - 0.05 * train.transpose() * (self.logistic(train * beta) - label) 
        return beta
    def classify(self , train , beta):
        prob = self.logistic(sum(train*beta))
        classification = "prob=" +prob.__str__+ "classifed as 0"
        if prob>0.5:
            classification="prob=" +prob.__str__+ "classifed as 2"
        return classification
                                
    def logistic(self,beta_x):
        return 1.0 / (1 + np.exp(-1*beta_x))
logisticregression = logisticregression()
beta_array = logisticregression.gradient_descent(np.mat(train) , np.mat(label).transpose())

XtB_test = np.dot(test, beta_array) 

predicted_test = 1.0 /( 1+ np.exp(-1*XtB_test))


'''
XtB_confusion = np.dot(train_confusion, beta_array) 
predicted_confusion = 1.0 /( 1+ np.exp(-1*XtB_confusion))
'''

predicted = np.squeeze(np.asarray(predicted_test))

logistic_confusion_matrix = confusion_matrix(predicted,test_label_flatten)


for n,i in enumerate(predicted_test):
    if i==1:
        predicted_test[n]=2


#ROC

false_positive_rate, true_positive_rate, thresholds = roc_curve(test_label_flatten,predicted)
roc_auc = auc(false_positive_rate, true_positive_rate)

plt.title('Receiver Operating Characteristic')
plt.plot(false_positive_rate, true_positive_rate, 'b',
label='AUC = %0.2f'% roc_auc)
plt.legend(loc='lower right')
plt.plot([0,1],[0,1],'r--')
plt.xlim([0,1.0])
plt.ylim([0,1.0])
plt.ylabel('True Positive Rate')
plt.xlabel('False Positive Rate')
plt.show()
