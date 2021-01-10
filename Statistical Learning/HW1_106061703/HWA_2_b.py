# -*- coding: utf-8 -*-
"""
Created on Tue Apr 17 10:12:10 2018

@author: 藍國瑞
"""

import csv
import numpy as np
from sklearn.metrics import confusion_matrix
from sklearn.naive_bayes import GaussianNB
from scipy.stats import multivariate_normal
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis

label=[]
train=[]
test=[]
all_data=[]

with open('train_MNIST_LDA.csv', newline='') as f:
    next(csv.reader(f))

    for row in csv.reader(f):
        train.append(row[1:]) 
        label.append(row[0])
        all_data.append(row[0:])
        
with open('test_MNIST_LDA.csv', newline='') as f:


    for row in csv.reader(f):
        test.append(row)

        
test_label=np.zeros(shape=(1382,1))
test_real=[]
with open('test_label.csv', newline='') as f:
    
     for row in csv.reader(f):
         test_real.append(row)
         
test_real=np.array(test_real)
for i in range(1382):
    test_label[i][0]=test_real[i][3]


test=np.array(test,dtype=np.float64)
train=np.array(train,dtype=np.float64)
label=np.array(label,dtype=np.float64)
all_data=np.array(all_data,dtype=np.float64)



lda = LinearDiscriminantAnalysis()
pred = lda.fit(train, label).predict(test)

label_flatten = test_label.ravel()

LDA_confusion_matrix = confusion_matrix(label_flatten, pred).T


        