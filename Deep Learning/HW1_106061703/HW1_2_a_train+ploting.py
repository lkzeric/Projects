import csv 
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import pyplot
from mpl_toolkits.mplot3d import Axes3D
import random


def oneD_row_column(b):
    number_of_data=b.shape[0]
    output=np.zeros((number_of_data,1),dtype=np.float64)
    for i in range(number_of_data):
        output[i][0]=b[i]
    return output


def sum_of_products(w,b,x):
    return np.dot(w,x) + b
def sigmoid(z):
    return 1 / ( 1 + np.exp(-z) ) 
def tanh(z):
    return ( 1 - np.exp(-2*z) ) / ( 1 + np.exp(-2*z) ) 
def softmax(z,k):
    a = np.exp(z[k])
    b = 0
    for i in range(len(z)):
        b += np.exp(z[i])
    if b == 0:
        b = 0.0000001
    return a / b
def cross_entropy(y,t):
    logy = np.log(y)
    logy[logy == 0] = 0.0000001
    return -np.dot(t,logy)
def sum_of_squares(y,t):
    return np.dot(y-t,y-t) / 2
def activate(mode,z):
    if mode == 'sigmoid':
        return sigmoid(z)
    elif mode == 'tanh':
        return tanh(z)
def cost(mode,y,t):
    if mode == 'cross entropy':
        return cross_entropy(y,t)
    elif mode == 'sum of squares':
        return sum_of_squares(y,t)
def d_cross_entropy(y,t):
    return -t / y
def d_sum_of_squares(y,t):
    return y - t
def d_softmax(z,k,l):
    if k == l:
        return softmax(z,l) * ( 1 - softmax(z,k) )
    else:
        return - softmax(z,l) * softmax(z,k)
def d_sigmoid(z):
    return sigmoid(z) * ( 1 - sigmoid(z) )
def d_tanh(z):
    return 4 / ( np.exp(z) + np.exp(-z) )**2
def d_activate(mode,z):
    if mode == 'sigmoid':
        return d_sigmoid(z)
    elif mode == 'tanh':
        return d_tanh(z)
def d_cost(mode,y,t):
    if mode == 'cross entropy':
        return d_cross_entropy(y,t)
    elif mode == 'sum of squares':
        return d_sum_of_squares(y,t)

learningRate = 0.0001
epoch = 2000
ACTIVATE = 'tanh'
COST = 'cross entropy'
NumX = 34
NumY = 2
NumH = 10
csv_file = 'ionosphere_data.csv'
file = open(csv_file,'r')
data = list(csv.reader(file))
data=np.take(data,np.random.permutation(len(data)),axis=0)
file.close
NumData = len(data)
dataX = np.zeros((NumData,NumX))
dataT = np.zeros((NumData,NumY))
for i in range(NumData):
    for j in range(NumX):
        dataX[i,j] = float(data[i][j])
for i in range(NumData):
    if data[i][NumX] == 'g':
        dataT[i,0] = 1
    elif data[i][NumX] == 'b':
        dataT[i,1] = 1
NumData_train = 280
NumData_test = 71

dataX_train = np.zeros((NumData_train,NumX))
dataX_test = np.zeros((NumData_test,NumX))
dataX_train[:280,:] = dataX[:280,:]
dataX_test[:71,:] = dataX[280:351,:]

dataT_train = np.zeros((NumData_train,NumY))
dataT_test = np.zeros((NumData_test,NumY))
dataT_train[:280,:] = dataT[:280,:]
dataT_test[:71,:] = dataT[280:351,:]

x = np.zeros(NumX)
z = np.zeros(NumH)
a = np.zeros(NumH)
y = np.zeros(NumY)
y_ = np.zeros(NumY)
y_train = np.zeros(NumY)
y_test = np.zeros(NumY)
t = np.zeros(NumY)
E = np.zeros(1)

d_z = np.zeros(NumH)
d_a = np.zeros(NumH)
d_y = np.zeros(NumY)
d_y_ = np.zeros(NumY)
buffer = np.zeros(NumY)

w1 = np.random.randn(NumX,NumH) * np.sqrt(2/34+10)
w2 = np.random.randn(NumH,NumY) * np.sqrt(2/2+10)
b1 = np.zeros(NumH)
b2 = np.zeros(NumY)

lossHistory=[]
y_node_0=[]
y_node_1=[]
y_node=[]
y_class_1=[]
y_class_2=[]
node=[]
y_softmax=[]
##########
# TRAIN ##
for loop in range(epoch):
    epochLoss=[]
    for index in range(NumData_train):
#######################################################
# BACKPROPAGATION -- FORWARD PASS
        x = dataX_train[index,:]
        t = dataT_train[index,:]
        for i in range(NumH):
            z[i] = sum_of_products(w1[:,i],b1[i],x)
            a[i] = activate(ACTIVATE,z[i])
        node.append((z[0],z[1],z[2]))
        for i in range(NumY):
            y[i] = sum_of_products(w2[:,i],b2[i],a)
            y_node.append((y[0],y[1]))
            #y_node_1.append(y[1])
          
        for i in range(NumY):
            y_[i] = softmax(y,i)
        
        y_softmax.append((y_[0],y_[1]))
        E = cost(COST,y_,t)
        epochLoss.append(E)
#######################################################
# BACKPROPAGATION -- BACKWARD PASS
        for i in range(NumY):
            d_y_[i] = d_cost(COST,y_[i],t[i])
        for i in range(NumY):
            for j in range(NumY):
                buffer[j] = d_softmax(y,i,j)
            d_y[i] = sum_of_products(buffer,0,d_y_)
        for i in range(NumH):
            d_a[i] = sum_of_products(w2[i,:],0,d_y)
            d_z[i] = d_activate(ACTIVATE,z[i]) * d_a[i]
#######################################################
# STOCHASTIC GRADIENT DESCENT
        for i in range(NumH):
            b1[i] -= learningRate * d_z[i]
            for j in range(NumX):
                w1[j,i] -= learningRate * x[j] * d_z[i]
        for i in range(NumY):
            b2[i] -= learningRate * d_y[i]
            for j in range(NumH):
                w2[j,i] -= learningRate * a[j] * d_y[i]  
    lossHistory.append(np.average(epochLoss))
               
fig = plt.figure()
plt.plot(np.arange(0, epoch), lossHistory)
fig.suptitle("Training Loss")
plt.xlabel("Epoch #")
plt.ylabel("Loss")
plt.show()               
################# latent feature #################


class_1_index=[]
class_2_index=[]
y_softmax=np.array(y_softmax)
for i in range (len(y_softmax)):
    if y_softmax[i][0]>y_softmax[i][1]:
        class_1_index.append(i)
    else:
        class_2_index.append(i)
     

class_1_select=[]
class_2_select=[]
class_3_select=[]

for i in class_1_index:
    class_1_select.append(node[i])

for i in class_2_index:
    class_2_select.append(node[i])





class_1_select_node0=[]
class_1_select_node1=[]
class_1_select_node2=[]
class_2_select_node0=[]
class_2_select_node1=[]
class_2_select_node2=[]

for i in range (len(class_1_select)):
    class_1_select_node0.append(class_1_select[i][0])
    class_1_select_node1.append(class_1_select[i][1])
    class_1_select_node2.append(class_1_select[i][2])
for i in range (len(class_2_select)):
    class_2_select_node0.append(class_2_select[i][0])
    class_2_select_node1.append(class_2_select[i][1])
    class_2_select_node2.append(class_2_select[i][2])


################ plot the figure ###############


fig = pyplot.figure()
ax = Axes3D(fig)

fig.suptitle("3D feature")
ax.scatter(class_2_select_node0,class_2_select_node1,class_2_select_node2,c='red',label='class2')
ax.scatter(class_1_select_node0,class_1_select_node1,class_1_select_node2,c='blue',label='class1')
plt.legend()
plt.show() 







                
##########
# Train ##
result_train = np.zeros((NumData_train,NumY))
for index in range(NumData_train):
#######################################################
# BACKPROPAGATION -- FORWARD PASS
    x = dataX_train[index,:]
    t = dataT_train[index,:]
    for i in range(NumH):
        z[i] = sum_of_products(w1[:,i],b1[i],x)
        a[i] = activate(ACTIVATE,z[i])
    for i in range(NumY):
        y[i] = sum_of_products(w2[:,i],b2[i],a)
        #y_node_0.append(y[0])
        #y_node_1.append(y[1])
    for i in range(NumY):
        y_train[i] = softmax(y,i)
##################################
    result_train[index,:] = y_train[:]
  
result_train_label=np.zeros((result_train.shape[0],1))

for i in range (0,result_train.shape[0]):
    if result_train[i][0]>result_train[i][1]:
        result_train_label[i]=1
    else:
        result_train_label[i]=0
error_train=oneD_row_column(dataT_train[:,0])-result_train_label
train_error_rate=np.sum((error_train)**2) / 280
print("train_error_rate=",train_error_rate)


                
                
# TEST ##
result_test = np.zeros((NumData_test,NumY))
for index in range(NumData_test):
#######################################################
# BACKPROPAGATION -- FORWARD PASS
    x = dataX_test[index,:]
    t = dataT_test[index,:]
    for i in range(NumH):
        z[i] = sum_of_products(w1[:,i],b1[i],x)
        a[i] = activate(ACTIVATE,z[i])
    for i in range(NumY):
        y[i] = sum_of_products(w2[:,i],b2[i],a)
    for i in range(NumY):
        y_test[i] = softmax(y,i)
##################################
    result_test[index,:] = y_test[:]
    
result_test_label=np.zeros((result_test.shape[0],1))

for i in range (0,result_test.shape[0]):
    if result_train[i][0]>result_train[i][1]:
        result_test_label[i]=1
    else:
        result_test_label[i]=0
error_test=oneD_row_column(dataT_test[:,0])-result_test_label
test_error_rate=np.sum(error_test**2) / 71
print("test_error_rate=",test_error_rate)

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    