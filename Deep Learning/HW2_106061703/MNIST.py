# -*- coding: utf-8 -*-
"""
Created on Tue Nov 27 21:31:23 2018

@author: 藍國瑞
"""

import numpy as np
import pandas as pd 
from keras.utils import np_utils
import matplotlib.pyplot as plt
import tensorflow as tf
from keras.datasets import mnist

save_file = './model.ckpt'
np.random.seed(10)
alpha=0.001
(x_train_tmp,y_train_tmp),(x_test,y_test)=mnist.load_data()

x_train=x_train_tmp[5000:60000]
x_train_norm=x_train/255
y_train=y_train_tmp[5000:60000]

x_validation=x_train_tmp[0:5000]
x_validation_norm=x_validation/255
y_validation=y_train_tmp[0:5000]

x_test_norm=x_test/255


y_trainonehot=np_utils.to_categorical(y_train)
y_validationonehot=np_utils.to_categorical(y_validation)
y_testonehot=np_utils.to_categorical(y_test)

def next_batch(X, y, batchSize):
    

    list=[]
    for i in np.arange(0, X.shape[0], batchSize):

		# yield a tuple of the current batched data and labels
	     list.append((X[i:i + batchSize], y[i:i + batchSize]))
    return list

def plot_image(image):
    fig =plt.gcf()
    fig.set_size_inches(2,2)
    plt.imshow(image,cmap='binary')
    plt.show()   
    
    
def plot_image_labels_prediction(images,labels,prediction,idx,num=10):
    fig=plt.gcf()
    fig.set_size_inches(12,14)
    if (num>25):
        num=25
    for  i in range (0,num):
        ax=plt.subplot(5,5,1+i)
        ax.imshow(images[idx],cmap="binary")
        title="label="+str(labels[idx])
        if len(prediction)>0:
            title+=",predict"+str(prediction[idx])
            
        ax.set_title(title,fontsize=10)
        ax.set_xticks([]);ax.set_yticks([])
        idx+=1
    plt.show


def weight(shape):
    return tf.Variable(tf.truncated_normal(shape,stddev=0.1),name='W')

def bias(shape):
    return tf.Variable(tf.constant(0.1,shape=shape),name='b')

def conv2d(x,W):
    return tf.nn.conv2d(x,W, strides=[1,1,1,1],padding='SAME')
def max_pool_2x2(x):
    return tf.nn.max_pool(x,ksize=[1,2,2,1],strides=[1,2,2,1],padding='SAME')

with tf.name_scope('Input_Layer'):
    x=tf.placeholder("float",shape=[None,28,28])
    x_image=tf.reshape(x,[-1,28,28,1])

with tf.name_scope('C1_Conv'):
    W1=weight([5,5,1,16])
    b1=bias([16])
    Conv1=conv2d(x_image,W1)+b1
    C1_Conv=tf.nn.relu(Conv1)
    
with tf.name_scope('C1_Pool'):
    C1_Pool=max_pool_2x2(C1_Conv)
    
with tf.name_scope('C2_Conv'):
    W2=weight([5,5,16,36])
    b2=bias([36])
    Conv2=conv2d(C1_Pool,W2)+b2
    C2_Conv=tf.nn.relu(Conv2)

with tf.name_scope('C2_Pool'):
    C2_Pool=max_pool_2x2(C2_Conv)
    
with tf.name_scope('D_Flat'):
    D_Flat=tf.reshape(C2_Pool,[-1,1764])

with tf.name_scope('D_Hidden_Layer'):
    W3=weight([1764,128])
    b3=bias([128])
    D_Hidden=tf.nn.relu(tf.matmul(D_Flat,W3)+b3)
    D_Hidden_Dropout=tf.nn.dropout(D_Hidden,keep_prob=0.8)
    
with tf.name_scope('Output_Layer'):
    W4=weight([128,10])
    b4=bias([10])
    y_predict=tf.nn.softmax(tf.matmul(D_Hidden_Dropout,W4)+b4)
    
with tf.name_scope('optimizer'):
    y_label=tf.placeholder('float',shape=[None,10],name='y_label')
    loss_function=tf.reduce_mean(tf.nn.softmax_cross_entropy_with_logits(logits=y_predict,
                                                                         labels=y_label))
    '''
    regularizer1 = tf.nn.l2_loss(W1)
    regularizer2 = tf.nn.l2_loss(W2)
    regularizer3 = tf.nn.l2_loss(W3)
    regularizer4 = tf.nn.l2_loss(W4)
    
    loss_function = tf.reduce_mean(loss_function + alpha * (regularizer1+regularizer2+regularizer3+regularizer4))
    '''
    loss_function = tf.reduce_mean(loss_function)
    optimizer=tf.train.AdamOptimizer(learning_rate=0.0001).minimize(loss_function)
    
with tf.name_scope('evaluate_model'):
    correct_prediction=tf.equal(tf.argmax(y_predict,1),tf.argmax(y_label,1))
    accuracy=tf.reduce_mean(tf.cast(correct_prediction,'float'))
    
trainEpochs=20
batchsize=100
totalBatchs=x_train.shape[0]/batchsize
epoch_list=[]

train_accuracy_list=[]
test_accuracy_list=[]
validation_accuracy_list=[]

train_loss_list=[]

from time import time
startTime=time()


saver = tf.train.Saver()
with tf.Session() as sess:
    
    sess.run(tf.global_variables_initializer())

    for epoch in range (trainEpochs):

        i=1
        epoch_loss=[]
        epoch_acc=[]
        for( batch_x, batch_y) in next_batch(x_train_norm , y_trainonehot ,batchsize):
       
            sess.run(optimizer,feed_dict={x:batch_x, y_label:batch_y})
            batch_loss,batch_acc=sess.run([loss_function,accuracy],feed_dict={x:batch_x, y_label:batch_y})
                               
            epoch_loss.append(batch_loss)
            epoch_acc.append(batch_acc)
                                              
            print('--- epoch ---',epoch)
            print('--- batch ---',i)
            print('batch_loss',batch_loss)
            print('batch_acc',batch_acc)
            i=i+1
            
        #train_loss,train_acc=sess.run([loss_function,accuracy],feed_dict={x:x_train_norm, y_label:y_trainonehot})
        epoch_list.append(epoch)                                                              
        validation_acc=sess.run(accuracy,feed_dict={x:x_validation_norm, y_label:y_validationonehot})
        test_acc=sess.run(accuracy,feed_dict={x:x_test_norm, y_label:y_testonehot})                                                                   
        
        train_loss_list.append(np.average(epoch_loss))
        train_accuracy_list.append(np.average(epoch_acc))
        
        validation_accuracy_list.append(validation_acc)
        test_accuracy_list.append(test_acc)
        #print("Train Epoch:",'%02d'%(epoch+1),'Loss=','{:.9f}'.format(train_loss),'Accuracy=',train_acc)
    
    duration=time()-startTime
    print('Train Finished takes',duration)   
    saver.save(sess, save_file)
    
    
    


with tf.Session() as sess:
  
    saver.restore(sess, save_file)
    
    y_predict_onehot=sess.run(y_predict,feed_dict={x:x_test})
    conv1=sess.run(C1_Conv,feed_dict={x:x_test})
    c1_pool=sess.run(C1_Pool,feed_dict={x:x_test})
    
    conv2=sess.run(C2_Conv,feed_dict={x:x_test})
    c2_pool=sess.run(C2_Pool,feed_dict={x:x_test})
    
    hidden=sess.run(D_Hidden,feed_dict={x:x_test})
    hidden_drop=sess.run(D_Hidden_Dropout,feed_dict={x:x_test})
    
    weight1=sess.run(W1)
    weight2=sess.run(W2)
    weight3=sess.run(W3)
    weight4=sess.run(W4)
    #print('Weight1:',weight1)
    #print('Weight2:',weight2)
    #print('Weight3:',weight3)
    #print('Weight4:',weight4)
    
y_predict_final=np.argmax(y_predict_onehot,1)
difference=(y_predict_final==y_test)
location_wrong=np.where(difference==0)[0][0]
location_correct=np.where(difference==1)[0][0]
####### 
plt.figure()
plt.title('Learning curve')
plt.plot(epoch_list,train_loss_list,label='loss')
plt.ylabel('loss')
plt.xlabel('epoch')
plt.legend(['loss'],loc='upper left')
plt.savefig('E:\Deep learning Eric\MNIST\Learning curve.png')

#######
plt.figure()
plt.title('Accuracy')
plt.plot(epoch_list,train_accuracy_list,label='train_accuracy')
plt.plot(epoch_list,validation_accuracy_list,label='validation_accuracy')
plt.plot(epoch_list,test_accuracy_list,label='test_accuracy')
plt.ylabel('accuracy')
plt.xlabel('epoch')
plt.legend()
plt.savefig('E:\Deep learning Eric\MNIST\Acc.png')

#######
plt.figure()
plt.title('Histogram of conv1')
plt.hist(weight1.flatten())
plt.savefig('E:\Deep learning Eric\MNIST\conv1.png')


plt.figure()
plt.title('Histogram of conv2')
plt.hist(weight2.flatten())
plt.savefig('E:\Deep learning Eric\MNIST\conv2.png')


plt.figure()
plt.title('Histogram of dense1')
plt.hist(weight3.flatten())
plt.savefig('E:\Deep learning Eric\MNIST\dense1.png')


plt.figure()
plt.title('Histogram of output')
plt.hist(weight4.flatten())
plt.savefig('E:\Deep learning Eric\MNIST\output.png')

'''
######
plt.figure()
plt.imshow(x_test[location_wrong],cmap='binary')
#plt.savefig('E:\Deep learning Eric\MNIST_filter\label4predict9.png')
print('label',y_test[location_wrong],'predict',y_predict_final[location_wrong])


plt.figure()
plt.imshow(x_test[location_correct],cmap='binary')
#plt.savefig('E:\Deep learning Eric\MNIST_filter\label7predict7.png')
print('label',y_test[location_correct],'predict',y_predict_final[location_correct])

####

plt.figure()
plt.imshow(conv1[location_wrong,:,:,0],cmap='binary')

plt.figure()
plt.imshow(c1_pool[location_wrong,:,:,0],cmap='binary')

plt.figure()
plt.imshow(conv2[location_wrong,:,:,0],cmap='binary')

plt.figure()
plt.imshow(c2_pool[location_wrong,:,:,0],cmap='binary')


####

plt.figure()
plt.imshow(conv1[location_correct,:,:,0],cmap='binary')

plt.figure()
plt.imshow(c1_pool[location_correct,:,:,0],cmap='binary')

plt.figure()
plt.imshow(conv2[location_correct,:,:,0],cmap='binary')

plt.figure()
plt.imshow(c2_pool[location_correct,:,:,0],cmap='binary')
'''
