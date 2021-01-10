# -*- coding: utf-8 -*-
"""
Created on Sun Dec 23 14:46:18 2018

@author: 藍國瑞
"""

from numpy import array
from pickle import dump
from keras.utils import to_categorical
from keras.models import Sequential
from keras.layers import Dense
from keras.layers import LSTM
from keras.layers import  Dropout
from keras.layers import SimpleRNN
import matplotlib.pyplot as plt
from keras.callbacks import ModelCheckpoint



# load doc into memory
def load_doc(filename):
	# open the file as read only
	file = open(filename, 'r')
	# read all text
	text = file.read()
	# close the file
	file.close()
	return text

# save tokens to file, one dialog per line
def save_doc(lines, filename):
    data='\n'.join(lines)
    file=open(filename,'w')
    file.write(data)
    file.close

#plot 
def show_train_history(train_history,train,validation):
    plt.plot(train_history.history[train])
    plt.plot(train_history.history[validation])
    plt.title('Train History')
    plt.ylabel(train)
    plt.xlabel('Epoch')
    plt.legend(['train','validation'],loc='upper left')
    plt.show
    

'''

raw_text = load_doc('shakespeare_train.txt')
print(raw_text)


tokens=raw_text.split()
raw_text=' '.join(tokens)



#organize into sequences of character
length=10
sequences=list()
for i in range(length,len(raw_text)):
    seq=raw_text[i-length:i+1]
    sequences.append(seq)
    
print('Total Sequnces:',len(sequences))



out_filename='char_shakespeare_train.txt'
save_doc(sequences,out_filename)

'''

#load
in_filename='char_shakespeare_train.txt'
raw_text=load_doc(in_filename)
lines=raw_text.split('\n')

chars=sorted(list(set(raw_text)))
mapping=dict((c,i) for i,c in enumerate(chars))

sequences=list()
for line in lines:
    encoded_seq=[ mapping[char] for char in line ]
    sequences.append(encoded_seq)

vocab_size=len(mapping)
print('Vocabulary size',vocab_size)


sequences=array(sequences)
X,y=sequences[:,:-1],sequences[:,-1]



XX=X[0:500000,:]
yy=y[0:500000]
sequences=[to_categorical(x,num_classes=vocab_size) for x in XX]
X=array(sequences)
y=to_categorical(yy,num_classes=vocab_size)


#################### valid data #########################
'''
raw_text_2=load_doc('shakespeare_valid.txt')
print(raw_text_2)

tokens_2=raw_text_2.split()
raw_text_2=' '.join(tokens_2)



#organize into sequences of character
length=10
sequences_2=list()
for i in range(length,len(raw_text_2)):
    seq_2=raw_text_2[i-length:i+1]
    sequences_2.append(seq_2)
    
print('Total Sequnces:',len(sequences_2))


out_filename_2='char_shakespeare_valid.txt'
save_doc(sequences_2,out_filename_2)

'''

#load
in_filename_2='char_shakespeare_valid.txt'
raw_text_2=load_doc(in_filename_2)
lines_2=raw_text_2.split('\n')



# the valid data should use the same mapping dict as the training data
sequences_2=list()
for line in lines_2:
    encoded_seq_2=[ mapping[char_2] for char_2 in line ]
    sequences_2.append(encoded_seq_2)


sequences_2=array(sequences_2)
X_valid,y_valid=sequences_2[:,:-1],sequences_2[:,-1]



XX_valid=X_valid[0:150000,:]
yy_valid=y_valid[0:150000]
sequences_2=[to_categorical(x,num_classes=vocab_size) for x in XX_valid]
X_valid=array(sequences_2)
y_valid=to_categorical(yy_valid,num_classes=vocab_size)


# checkpoint
#filepath="weights-improvement-{epoch:02d}-{val_acc:.2f}.hdf5"
#filepath="weights.best.hdf5"
#checkpoint = ModelCheckpoint(filepath, monitor='val_acc', verbose=1, save_best_only=True, mode='max')
#callbacks_list = [checkpoint]

batch=10
# define model
model=Sequential()

model.add(LSTM(75,input_shape=(X.shape[1],X.shape[2]),batch_size=batch,return_sequences=True,stateful=True))
#model.add(SimpleRNN(75,input_shape=(X.shape[1],X.shape[2]),return_sequences=True))
model.add(Dropout(0.2))
model.add(LSTM(100,batch_size=batch,stateful=True))
model.add(Dropout(0.2))
model.add(Dense(vocab_size,activation='softmax'))
print(model.summary())

#compile model
model.compile(loss='categorical_crossentropy',optimizer='adam',metrics=['accuracy'])

#fit model
##for i in range (4):
train_history=model.fit(X,y,validation_data=(X_valid,y_valid),shuffle=False,epochs=30,batch_size=batch,verbose=2)
  ##  model.reset_states()

    
'''
plt.figure()
show_train_history(train_history,'loss','val_loss')
plt.figure()
show_train_history(train_history,'acc','val_acc')
'''

#save the model to file
#model.save('model.h5')

#save the mapping
#dump(mapping, open('mapping.pkl','wb'))




'''

from pickle import load
from keras.models import load_model
from keras.utils import to_categorical
from keras.preprocessing.sequence import pad_sequences

#generate a sequence of characters with a language model

def generate_seq(model,mapping,seq_length,seed_text,n_chars):
    in_text=seed_text
    for _ in range(n_chars):
        encoded=[mapping[char] for char in in_text]
        encoded=pad_sequences([encoded],maxlen=seq_length,truncating='pre')
        encoded=to_categorical(encoded,num_classes=len(mapping)) # one_hot vector
        #encoded=encoded.reshape(1,encoded.shape[0],encoded.shape[1])
        
        y_hat=model.predict_classes(encoded,verbose=0)

        out_char=' '
        for char, index in mapping.items():
            if index==y_hat:
                out_char=char
                break
        in_text+=out_char
    return in_text
  
    
    
#load the model
model=load_model('model.h5')
#load the mapping
mapping=load(open('mapping.pkl','rb'))
print(generate_seq(model,mapping,10,'Sing a son',20))
print(generate_seq(model, mapping, 10, 'king was i', 20))

'''















