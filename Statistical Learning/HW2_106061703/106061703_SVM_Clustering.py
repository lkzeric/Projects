# -*- coding: utf-8 -*-
"""
Created on Sun Jun 24 09:25:17 2018

@author: 藍國瑞
"""

##################################2(a)######################################
import csv
import numpy as np
from sklearn.svm import SVC
from sklearn.metrics import roc_curve, auc
import matplotlib.pyplot as plt
from sklearn.metrics import confusion_matrix

train=[]
label=[]


with open('MNIST_SVM.csv', newline='') as f:
    next(csv.reader(f))

    for row in csv.reader(f):
        train.append(row[1:]) 
        label.append(row[0])

train=np.array(train,dtype=float)
label=np.array(label,dtype=float)


### svc_10 ###
svc_shape=[]
svc1 = SVC(C= 10, kernel='linear')
svc1.fit(train, label)
no_1=svc1.support_.size
label_predicted_1=svc1.predict(train)
confusion_matrix_1=confusion_matrix(label,label_predicted_1)



svc1.support_
svc1.shape=svc1.support_.shape 





### svc_0.1 ###
svc2 = SVC(C= 0.1, kernel='linear')
svc2.fit(train, label)
no_2=svc2.support_.size
label_predicted_2=svc2.predict(train)
confusion_matrix_2=confusion_matrix(label,label_predicted_2)


### svc_0.01 ###
svc3 = SVC(C= 0.01, kernel='linear')
svc3.fit(train, label)
no_3=svc3.support_.size
label_predicted_3=svc3.predict(train)
confusion_matrix_3=confusion_matrix(label,label_predicted_3)


####################################2(b)#####################################

import csv
import numpy as np
from sklearn.svm import SVC



train=[]
label=[]


with open('MNIST_SVM.csv', newline='') as f:
    next(csv.reader(f))

    for row in csv.reader(f):
        train.append(row[1:]) 
        label.append(row[0])

train=np.array(train,dtype=float)
label=np.array(label,dtype=float)

### poly kernel with deg=1 ###
svc_1=SVC(kernel='poly',degree=1)
svc_1.fit(train,label)
label_predicted_1=svc_1.predict(train)


false_positive_rate, true_positive_rate, thresholds = roc_curve(label/2,label_predicted_1/2)
roc_auc = auc(false_positive_rate, true_positive_rate)

plt.title('Receiver Operating Characteristic,d=1')
plt.plot(false_positive_rate, true_positive_rate, 'b',
label='AUC = %0.2f'% roc_auc)
plt.legend(loc='lower right')
plt.plot([0,1],[0,1],'r--')
plt.xlim([0,1.0])
plt.ylim([0,1.0])
plt.ylabel('True Positive Rate')
plt.xlabel('False Positive Rate')
plt.show()


### poly kernel with deg=2 ###
svc_2=SVC(kernel='poly',degree=2)
svc_2.fit(train,label)
label_predicted_2=svc_2.predict(train)


false_positive_rate, true_positive_rate, thresholds = roc_curve(label/2,label_predicted_2/2)
roc_auc = auc(false_positive_rate, true_positive_rate)

plt.title('Receiver Operating Characteristic,d=2')
plt.plot(false_positive_rate, true_positive_rate, 'b',
label='AUC = %0.2f'% roc_auc)
plt.legend(loc='lower right')
plt.plot([0,1],[0,1],'r--')
plt.xlim([0,1.0])
plt.ylim([0,1.0])
plt.ylabel('True Positive Rate')
plt.xlabel('False Positive Rate')
plt.show()


### poly kernel with deg=3 ###
svc_3=SVC(kernel='poly',degree=3)
svc_3.fit(train,label)
label_predicted_3=svc_3.predict(train)


false_positive_rate, true_positive_rate, thresholds = roc_curve(label/2,label_predicted_3/2)
roc_auc = auc(false_positive_rate, true_positive_rate)

plt.title('Receiver Operating Characteristic,d=3')
plt.plot(false_positive_rate, true_positive_rate, 'b',
label='AUC = %0.2f'% roc_auc)
plt.legend(loc='lower right')
plt.plot([0,1],[0,1],'r--')
plt.xlim([0,1.0])
plt.ylim([0,1.0])
plt.ylabel('True Positive Rate')
plt.xlabel('False Positive Rate')
plt.show()




#################################2(c)####################################


import csv
import numpy as np
from sklearn.svm import SVC
from sklearn.metrics import roc_curve, auc
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
from copy import deepcopy
from sklearn import preprocessing


train=[]
label=[]


with open('MNIST_clustering.csv', newline='') as f:
    next(csv.reader(f))

    for row in csv.reader(f):
        train.append(row[1:]) 
        label.append(row[0])

train=preprocessing.scale(np.array(train,dtype=float))
label=np.array(label,dtype=float)

pca=PCA(n_components=2)  
newdata=pca.fit_transform(train)
first_pc=newdata[:,0]
second_pc=newdata[:,1]


k = 3
# X coordinates of random centroids
C_x = np.random.randint(0, np.max(newdata)-20, size=k)
# Y coordinates of random centroids
C_y = np.random.randint(0, np.max(newdata)-20, size=k)
C = np.array(list(zip(C_x, C_y)), dtype=np.float32)
print(C)


def dist(a, b, ax=1):
    return np.linalg.norm(a - b, axis=ax)

# To store the value of centroids when it updates
C_old = np.zeros(C.shape)
# Cluster Lables(0, 1, 2)
clusters = np.zeros(len(newdata))
# Error func. - Distance between new centroids and old centroids
error = dist(C, C_old, None)
# Loop will run till the error becomes zero
while error != 0:
    # Assigning each value to its closest cluster
    for i in range(len(newdata)):
        distances = dist(newdata[i], C)
        cluster = np.argmin(distances)
        clusters[i] = cluster
    # Storing the old centroid values
    C_old = deepcopy(C)
    # Finding the new centroids by taking the average value
    for i in range(k):
        points = [newdata[j] for j in range(len(newdata)) if clusters[j] == i]
        C[i] = np.mean(points, axis=0)
    error = dist(C, C_old, None)
colors = [ 'y', 'c', 'm','r', 'g', 'b',]
fig, ax = plt.subplots(figsize=(8,5))
for i in range(k):
        points = np.array([newdata[j] for j in range(len(newdata)) if clusters[j] == i])
        ax.scatter(points[:, 0], points[:, 1], s=7, c=colors[i])
ax.scatter(C[:, 0], C[:, 1], marker='*', s=100, c='#050505')

fig, bx = plt.subplots(figsize=(8,5))
for i in range(k):
        points = np.array([newdata[j] for j in range(len(newdata)) if label[j] == 2*i])
        bx.scatter(points[:, 0], points[:, 1], s=7, c=colors[i])








