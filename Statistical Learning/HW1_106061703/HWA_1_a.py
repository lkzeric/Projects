# -*- coding: utf-8 -*-
"""
Created on Sun Apr  8 15:22:25 2018

@author: 藍國瑞
"""


import csv
import numpy as np
import scipy.stats

from numpy.linalg import inv


one_day_datas = []
year_datas = []
all_datas = []
PM25_datas = []


with open('data_Hsinchu.csv', newline='') as f:
    count=0
    next(csv.reader(f))
    for row in csv.reader(f):
        for i in range(len(row)):
            if row[i] == 'NR':
                 row[i]='0'
            
        one_day_datas.append(row[3:]) 

        count = count +1
        if(row[2]== 'PM2.5'):
            PM25_datas = PM25_datas + row[3:]
        if( count == 18 ):
            one_day_datas=np.delete(one_day_datas,9,axis=0)
            one_day_datas=np.transpose(one_day_datas)
            if len(year_datas) == 0:
                year_datas = list(one_day_datas)
            else:
                year_datas = np.concatenate((year_datas,one_day_datas),axis=0)
            one_day_datas = []
            count = 0
year_datas = np.array(year_datas,dtype=np.float64)
PM25_datas = np.array(PM25_datas,dtype=np.float64)   	
X=np.concatenate((np.ones((len(year_datas),1),dtype=np.float64),year_datas),axis=1)
Y=PM25_datas

'''(a)'''
#coefficient        

X1=np.dot(np.transpose(X),X)
X2=inv(X1)
X3=np.dot(X2,np.transpose(X))
coeff=np.dot(X3,Y)

#Std Error
Est = np.dot(X,coeff)
E = Y - Est
rss=np.dot(np.transpose(E),E)
Bias = rss / (8760-17-1)


Beta_std = np.sqrt(np.diag(X2*Bias))

#t-statistic
T = np.zeros((len(coeff),1))
for i in range (len(coeff)):
    T[i]=coeff[i] / Beta_std[i]


#p-value   
pval = np.zeros(shape=(18))
for i in range(18):
    pval[i] = scipy.stats.t.sf(np.abs(T[i]), 8760-1)
    
#RSE
rse=np.sqrt( rss / (8760-17-1))

#R_square
y_mean=np.mean(Y)
y_mean_bias = Y-y_mean
tss = np.dot(np.transpose(y_mean_bias),y_mean_bias)
r_square = 1-(rss/tss)


  
     





