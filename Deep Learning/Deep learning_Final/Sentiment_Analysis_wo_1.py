# -*- coding: utf-8 -*-
"""
Created on Tue Jan  8 16:17:30 2019

@author: 沈彤 & 藍國瑞
"""

import matplotlib.pyplot as plt
import numpy as np
from numpy import array
from pickle import dump
from keras.utils import to_categorical
from keras.models import Sequential
from keras.layers.embeddings import Embedding
from keras.layers import Dense
from keras.layers import LSTM
from keras.layers import SpatialDropout1D
from keras.layers import  Dropout
from keras.layers import GaussianNoise
from keras.callbacks import ModelCheckpoint
from keras.preprocessing import sequence
import pandas as pd
from matplotlib.pyplot import *
import collections
import tensorflow as tf
import keras
from keras.layers import BatchNormalization
import random
from keras.layers import Bidirectional
#import gensim 

thre = 50
length = thre
#num_vocab = 10000
num_vocab_other = 2
#num_vocab_total = num_vocab + num_vocab_other
levels = 5

EMBEDDING_SIZE = 256
HIDDEN_LAYER_SIZE = 128
BATCH_SIZE = 256
NUM_EPOCHS = 50

def show_train_history(train_history, train, validation):
    figure().set_size_inches(10, 6)
    plot(train_history.history[train],'b',linewidth=1.5)
    plot(train_history.history[validation],'r',linewidth=1.5)
    xticks(fontsize=8)
    yticks(fontsize=8)
    title("Train " + train + " curve",fontsize=18)
    ylabel(train)
    xlabel('Epoch')
    legend(['train', 'validation'], loc='center right')
    savefig("train_history_" + train + ".png")
    show()
#讀資料
def load_data(dir_data):
    data = pd.read_csv(dir_data, sep='\t')
    return list(data[data.columns[2]]) , list(data[data.columns[3]])
#每一句話分割成一個個單字
def sentence_to_words(sentence):
    words = list()
    for i in range(len(sentence)):
        words.append(sentence[i].split(' '))
    return words
#攤平所有句子的單字
def flatten_the_words(words):
    flat = list()
    for i in range(len(words)):
        for j in range(len(words[i])):
            flat.append(words[i][j])
    return flat
#強制轉換成小寫字母
def lower_char(words):
    for i in range(len(words)):
        for j in range(len(words[i])):
            words[i][j] = words[i][j].lower()
#強制轉換成小寫字母
def is_number(words):
    for i in range(len(words)):
        for j in range(len(words[i])):
            if any(char.isdigit() for char in words[i][j]):
                words[i][j] = '1'
#句子長度:每一句話有多少單字
def length_of_sentence(sentence):
    num = list()
    for i in range(len(sentence)):
        num.append(len(sentence[i]))
    return num
#句子長度分布直方圖
def plot_histogram(x):
    hist(x,bins=100)
    title('Histogram',fontsize=18)
    xlabel('Value')
    ylabel('Number')
    savefig('Histogram.png')
    show()
    return
#沒有重覆的 按照字母排列的單字
def sort_the_words(words):
    return sorted(list(set(words)))
#重覆的 按照字母排列的單字
def sort_the_repeated_words(words):
    return sorted(words)
#每個單字出現幾次
def how_many_words(w):
    y = collections.Counter()
    for i in w:
        y[i] += 1
    return y
#def train_generator(max_num=num_vocab_total,batch=BATCH_SIZE):
#    while True:
#        sequence_length = np.random.randint(1, 7)
#        x_train = np.random.randint(max_num,size=(batch,sequence_length))
#        y_train = np.zeros((batch,5))
#        sumX = np.zeros(batch)
#        for i in range(sequence_length):
#            sumX[:] += x_train[:,i]  
#        for i in range(5):
#            y_train[sumX[i]<(max_num*sequence_length/5*(i+1)), i] = 1
#        yield x_train, y_train
#def decode(x):
#    X = np.zeros((BATCH_SIZE,len(x[0]),EMBEDDING_SIZE))
#    for i in range(BATCH_SIZE):
#        for j in range(len(x[0])):
#            X[i,j,:] = W2V[dictionary_index2word[x[i][j]],:]
#    return X
#輸出批量資料
def take_train_batch():
    index_train = 0
    randnum_train = [i for i in range( num_train_batch )]
    random.shuffle(randnum_train)
    while True:
        randnum_train = [i for i in range( num_train_batch )]
        random.shuffle(randnum_train)
        x1 = array(X_train_batches[randnum_train[index_train]])
        y1 = array(Y_train_batches[randnum_train[index_train]])
#        x1 = decode(x1)
        index_train += 1
        if index_train == num_train_batch:
            index_train = 0
        yield x1, y1
def take_test_batch():
    index_test = 0
    randnum_test = [i for i in range( num_test_batch )]
    random.shuffle(randnum_test)
    while True:
        randnum_test = [i for i in range( num_test_batch )]
        random.shuffle(randnum_test)
        x2 = array(X_test_batches[randnum_test[index_test]])
        y2 = array(Y_test_batches[randnum_test[index_test]])
        index_test += 1
        if index_test == num_test_batch:
            index_test = 0
        yield x2, y2
#分割成批量資料
def batching(x,y,batch=BATCH_SIZE,l=thre):
    num_words = array(length_of_sentence(x))
    randnum = [i for i in range( len(x) )]
    random.shuffle(randnum)
    xx = list()
    yy = list()
    for i in range( len(x) ):
        xx.append(x[randnum[i]])
        yy.append(y[randnum[i]])
    xx = array(xx)
    yy = array(yy)
    x_cat = list()
    y_cat = list()
    X = list()
    Y = list()
    for i in range(1,l+1):
        x_cat.append(x[num_words == i])
        y_cat.append(y[num_words == i,:])
    for i in range(l):
        num_batch = int( len(x_cat[i]) / batch )
        x_batch = list()
        y_batch = list()
        x_ = list(x_cat[i])
        y_ = list(y_cat[i])
        for j in range(num_batch-1):
            x_batch.append(x_[j*batch:(j+1)*batch])
            y_batch.append(y_[j*batch:(j+1)*batch])
        x_batch.append(x_[(num_batch-1)*batch:])
        y_batch.append(y_[(num_batch-1)*batch:])
        X.append(x_batch)
        Y.append(y_batch)
    return X,Y
#合併所有批量資料
def combine_batch(x,y,l=thre):
    xb = list()
    yb = list()
    nb = 0
    for i in range(l):
        xb.extend(x[i])
        yb.extend(y[i])
    nb = len(xb)
    return xb,yb,nb
def delete_some_neutral():
    delete_index = array(Sentiment_train)!=2
    Ph = list()
    Se = list()
    for i in range(len(Sentiment_train)):
        if delete_index[i]:
            Ph.append(tokens_train[i])
            Se.append(Sentiment_train[i])
    Ph_2 = list()
    Se_2 = list()
    for i in range(len(Sentiment_train)):
        if not delete_index[i]:
            Ph_2.append(tokens_train[i])
            Se_2.append(Sentiment_train[i])
    randnum = [i for i in range( len(Ph_2) )]
    random.shuffle(randnum)
    keep_rate = 0.5
    for i in range(int(len(Ph_2)*keep_rate)):
        Ph.append(Ph_2[randnum[i]])
        Se.append(Se_2[randnum[i]])
    return Ph,Se
        
Phrase , Sentiment = load_data('train.tsv')

tokens = sentence_to_words(Phrase)
lower_char(tokens)
is_number(tokens)
num_tokens = length_of_sentence(tokens)

num_tokens = np.array(num_tokens)

tokens_short = array(tokens)[num_tokens<=thre]
Sentiment_short = array(Sentiment)[num_tokens<=thre]
num_train = int(len(tokens_short)*0.8)
num_test = len(tokens_short) - num_train

tokens_train = tokens[:num_train]
Sentiment_train = Sentiment[:num_train]


################
'''
model_w2v = gensim.models.Word2Vec (tokens_train, size=EMBEDDING_SIZE-num_vocab_other, window=8,iter=100,negative=10,min_count=0, max_vocab_size=None, workers=10)
model_w2v.train(tokens_train,total_examples=len(tokens_train),epochs=100)
model_w2v.save("w2v.model")
w2v = model_w2v.wv
'''
################

#tokens_train , Sentiment_train = delete_some_neutral()

tokens_test = tokens_short[num_train:]
Sentiment_test = Sentiment_short[num_train:]

num_sentences = len(tokens)
num_sentences_short = len(tokens_short)
num_sentences_train = len(tokens_train)
num_sentences_test = len(tokens_test)

plot_histogram(num_tokens)

tokens_flat = flatten_the_words(tokens)
tokens_train_flat = flatten_the_words(tokens_train)
tokens_test_flat = flatten_the_words(tokens_test)

words = sort_the_words(tokens_flat)
words_train = sort_the_words(tokens_train_flat)
words_test = sort_the_words(tokens_test_flat)

words_repeat = sort_the_repeated_words(tokens_flat)
words_train_repeat = sort_the_repeated_words(tokens_train_flat)
words_test_repeat = sort_the_repeated_words(tokens_test_flat)

num_words = how_many_words(words_repeat)
num_words_train = how_many_words(words_train_repeat)
num_words_test = how_many_words(words_test_repeat)

num_all_vocab = len(num_words)
num_train_vocab = len(num_words_train)
num_test_vocab = len(num_words_test)
num_vocab = num_train_vocab
num_vocab_total = num_vocab + num_vocab_other

all_vocab = num_words.most_common(num_all_vocab)
train_vocab = num_words_train.most_common(num_train_vocab)
test_vocab = num_words_test.most_common(num_test_vocab)

vocab = num_words_train.most_common(num_vocab)
#dictionary_words = dict((c,i) for i,c in enumerate(words))


############################
'''
dictionary_word2index = {x[0]: i+1 for i, x in enumerate(vocab)}
dictionary_word2index["OTHER_NONE"] = 0
dictionary_word2index["OTHER_VOCAB"] = num_vocab+1
dictionary_index2word = {v:k for k, v in dictionary_word2index.items()}

W2V = np.zeros((num_vocab_total,EMBEDDING_SIZE))
for i in range(num_vocab):
    W2V[i+1,1:-1] = w2v[dictionary_index2word[i+1]]
W2V[0,0] = 1
W2V[num_vocab+1,-1] = 1
'''
###########################


#X = np.empty(num_sentences,dtype=list)
#Y = np.zeros((num_sentences,levels))
X_train = np.empty(num_sentences_train,dtype=list)
Y_train = np.zeros((num_sentences_train,levels))
X_test = np.empty(num_sentences_test,dtype=list)
Y_test = np.zeros((num_sentences_test,levels))

#i=0
#for line in tokens:
#    encoded_seq = list()
#    for w in line:
#        if w in dictionary_word2index:
#            encoded_seq.append(dictionary_word2index[w])
#        else :
#            encoded_seq.append(dictionary_word2index["OTHER_VOCAB"])
#    X[i] = encoded_seq
#    i+=1

i=0
for line in tokens_train:
    encoded_seq = list()
    for w in line:
        if w in dictionary_word2index:
            encoded_seq.append(dictionary_word2index[w])
        else :
            encoded_seq.append(dictionary_word2index["OTHER_VOCAB"])
    X_train[i] = encoded_seq
    i+=1
Y_train = np.array(Sentiment_train)
i=0
for line in tokens_test:
    encoded_seq = list()
    for w in line:
        if w in dictionary_word2index:
            encoded_seq.append(dictionary_word2index[w])
        else :
            encoded_seq.append(dictionary_word2index["OTHER_VOCAB"])
    X_test[i] = encoded_seq
    i+=1
Y_test = np.array(Sentiment_test)

Y_train = to_categorical(Y_train , num_classes = levels)
Y_test = to_categorical(Y_test , num_classes = levels)
#X_short = X[num_tokens<=thre]
#X_long = X[num_tokens>thre]
#Y_short = np.array(Sentiment)[num_tokens<=thre]
#Y_long = np.array(Sentiment)[num_tokens>thre]
#
#Y_short = to_categorical(Y_short , num_classes = levels)
#Y_long = to_categorical(Y_long , num_classes = levels)
#
#num_train = int(len(X_short)*0.8)
#num_test = len(X_short) - num_train
#
#X_train = X_short[:num_train]
#Y_train = Y_short[:num_train,:]
#X_test = X_short[num_train:]
#Y_test = Y_short[num_train:,:]

X_train_batches, Y_train_batches = batching(X_train,Y_train)
X_test_batches, Y_test_batches = batching(X_test,Y_test)
X_train_batches, Y_train_batches, num_train_batch = combine_batch(X_train_batches, Y_train_batches)
X_test_batches, Y_test_batches, num_test_batch = combine_batch(X_test_batches, Y_test_batches)

gpu_options = tf.GPUOptions(per_process_gpu_memory_fraction=0.4)  
sess = tf.Session(config=tf.ConfigProto(gpu_options=gpu_options))
tf.keras.backend.set_session(sess)

############  Glove #############


from keras.preprocessing.text import Tokenizer

vocabulary_size = num_vocab
tokenizer = Tokenizer(num_words= vocabulary_size)
tokenizer.fit_on_texts(Phrase)




embeddings_index = dict()
f = open('glove.6B.100d.txt')
for line in f:
    values = line.split()
    word = values[0]
    coefs = np.asarray(values[1:], dtype='float32')
    embeddings_index[word] = coefs
f.close()

embedding_matrix = np.zeros((num_all_vocab, 100))
for word, index in tokenizer.word_index.items():
    if index > num_vocab - 1:
        break
    else:
        embedding_vector = embeddings_index.get(word)
        if embedding_vector is not None:
            embedding_matrix[index] = embedding_vector




#################################


model = Sequential()
model.add(Embedding(num_vocab_total , EMBEDDING_SIZE , weights = [embedding_matrix] , embeddings_regularizer = keras.regularizers.l2(2e-6),trainable = False))
#model.add(GaussianNoise(0.0005))
#model.add(SpatialDropout1D(rate=0.5))
#model.add(BatchNormalization(axis=2, momentum=0.9, epsilon=0.001, center=True, scale=False))
#model.add(ConvLSTM2D(64,kernel_size=3,strides=1,dilation_rate=1, dropout=0.5, recurrent_dropout=0.5, stateful=False , return_sequences=True,
#               kernel_regularizer = keras.regularizers.l2(1e-6),
#               recurrent_regularizer = keras.regularizers.l2(1e-6)))
#model.add(LSTM(128, dropout=0.5, recurrent_dropout=0.5, stateful=False , return_sequences=True,
#               kernel_regularizer = keras.regularizers.l2(1e-6),
#               recurrent_regularizer = keras.regularizers.l2(1e-6)))
#model.add(GaussianNoise(0.001))
#model.add(BatchNormalization(axis=2, momentum=0.9, epsilon=0.001, center=True, scale=False))
#model.add(LSTM(128, dropout=0.6, recurrent_dropout=0.5, stateful=False , return_sequences=True,
#               kernel_regularizer = keras.regularizers.l2(1e-6),
#               recurrent_regularizer = keras.regularizers.l2(1e-6)))
model.add(Bidirectional(LSTM(64,input_shape = (None,None,EMBEDDING_SIZE), dropout=0.6, recurrent_dropout=0.5, stateful=False, return_sequences=True,
               kernel_regularizer=keras.regularizers.l2(1e-6),
               recurrent_regularizer = keras.regularizers.l2(1e-6))))
#model.add(GaussianNoise(0.001))
model.add(BatchNormalization(axis=2, momentum=0.9, epsilon=0.001, center=True, scale=False))
#model.add(LSTM(128, dropout=0.6, recurrent_dropout=0.5, stateful=False , return_sequences=True,
#               kernel_regularizer=keras.regularizers.l2(3e-6),
#               recurrent_regularizer = keras.regularizers.l2(3e-6)))
#model.add(Bidirectional(LSTM(64, dropout=0.6, recurrent_dropout=0.5, stateful=False, return_sequences=True,
#               kernel_regularizer=keras.regularizers.l2(1e-6),
#               recurrent_regularizer = keras.regularizers.l2(1e-6))))
#model.add(GaussianNoise(0.001))
#model.add(BatchNormalization(axis=2, momentum=0.9, epsilon=0.001, center=True, scale=False))
#model.add(LSTM(128, dropout=0.6, recurrent_dropout=0.5, stateful=False,
#               kernel_regularizer=keras.regularizers.l2(5e-6),
#               recurrent_regularizer = keras.regularizers.l2(5e-6)))
model.add(Bidirectional(LSTM(64, dropout=0.6, recurrent_dropout=0.5, stateful=False,
               kernel_regularizer=keras.regularizers.l2(3e-6),
               recurrent_regularizer = keras.regularizers.l2(3e-6))))
#model.add(GaussianNoise(0.001))
model.add(BatchNormalization(axis=1, momentum=0.9, epsilon=0.001, center=True, scale=False))
#model.add(Dense(32,activation="relu",kernel_regularizer=keras.regularizers.l2(1e-6)))
#model.add(Dropout(rate=0.2))
model.add(Dense(levels,activation='softmax',kernel_regularizer=keras.regularizers.l2(6e-6)))

print (model.summary())

RMSprop = keras.optimizers.RMSprop(lr=0.0005, rho=0.9, epsilon=1e-8, decay=0.00)
adam = keras.optimizers.Adam(lr=0.0015,decay=0, beta_1=0.9, beta_2=0.999, epsilon=1e-08)

ES1 = keras.callbacks.EarlyStopping(monitor='val_loss', patience=5, verbose=1, mode='min')
ES2 = keras.callbacks.EarlyStopping(monitor='val_acc', patience=5, verbose=1, mode='max')

model.compile(loss="categorical_crossentropy", optimizer = RMSprop ,metrics=["accuracy"])
train_history = model.fit_generator( take_train_batch(), steps_per_epoch = num_train_batch, epochs = NUM_EPOCHS ,
                                    validation_data = take_test_batch(), validation_steps = num_test_batch,
                                    shuffle = False,callbacks=[ES1,ES2])
#train_history = model.fit_generator(train_generator(), steps_per_epoch = 1000, epochs = NUM_EPOCHS ,
#                          validation_data = train_generator() ,validation_steps = 50, shuffle = True)
#train_history = model.fit(X_train, Y_train, batch_size = BATCH_SIZE, epochs = NUM_EPOCHS ,
#                          validation_data=(X_test, Y_test) , shuffle = True)

model.save('Sentiment_Analysis.h5')

weights = np.array(model.get_weights())

show_train_history(train_history,'acc','val_acc')
show_train_history(train_history,'loss','val_loss')

