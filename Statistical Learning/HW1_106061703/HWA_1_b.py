# -*- coding: utf-8 -*-
"""
Created on Mon Apr  9 11:06:45 2018

@author: 藍國瑞
"""

import csv
import numpy as np
import scipy.stats
from numpy.linalg import inv
from itertools import combinations
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import axes3d


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


X_dec = np.zeros((8760,2),dtype=np.float64)
X_combine=np.zeros((8760,2),dtype=np.float64)


#find two predictor to achieve the minimum RSS   	
comb = np.zeros((136,2),dtype=np.float64)
rss  = np.zeros((136,1),dtype=np.float64)
a = 0
for two in combinations(range(17), 2):
    comb[a][0] = two[0]
    comb[a][1] = two[1]
    a += 1

for choice in range(136):
    dec_1=comb[choice][0]
    dec_2=comb[choice][1]
    a=int(dec_1)
    b=int(dec_2)
    X_dec1 = year_datas[:,a]
    X_dec2 = year_datas[:,b]
    X_combine=np.vstack((X_dec1,X_dec2))  
    X_set=np.transpose(X_combine)
    X_final=np.concatenate((np.ones((len(X_set),1),dtype=np.float64),X_set),axis=1)
    
    X1=np.dot(np.transpose(X_final),X_final)
    X2=inv(X1)
    X3=np.dot(X2,np.transpose(X_final))
    coeff=np.dot(X3,Y)
    
    Est = np.dot(X_final,coeff)
    E = Y - Est
    rss[choice] = np.dot(np.transpose(E),E)
rss_result = min(rss)
choice_result = np.argmin(rss)

Feature1 = int(comb[choice_result][0])
Feature2 = int(comb[choice_result][1])
 
X_Feature1 = year_datas[:,Feature1]
X_Feature2 = year_datas[:,Feature2]
X_F1F2_temp = np.vstack((X_Feature1,X_Feature2))
X_F1F2 = np.transpose(X_F1F2_temp)
X_F1F2_final = np.concatenate((np.ones((len(X_F1F2),1),dtype=np.float64),X_F1F2),axis=1)


#coefficient 
X11=np.dot(np.transpose(X_F1F2_final),X_F1F2_final)
X22=inv(X11)
X33=np.dot(X22,np.transpose(X_F1F2_final))
coeff_final=np.dot(X33,Y)
    
#Std Error
Est = np.dot(X_F1F2_final,coeff_final)
E = Y - Est
rss=np.dot(np.transpose(E),E)
Bias = rss / (8760-2-1)
Beta_std = np.sqrt(np.diag(X22*Bias))

#t-statistic
T = np.zeros((len(coeff_final),1))
for i in range (len(coeff_final)):
    T[i]=coeff_final[i] / Beta_std[i]


#p-value   
pval = np.zeros(shape=(3))
for i in range(3):
    pval[i] = scipy.stats.t.sf(np.abs(T[i]), 8760-1)
    
#RSE
rse=np.sqrt( rss / (8760-2-1))

#R_square
y_mean=np.mean(Y)
y_mean_bias = Y-y_mean
tss = np.dot(np.transpose(y_mean_bias),y_mean_bias)
r_square = 1-(rss/tss)

    
    
    