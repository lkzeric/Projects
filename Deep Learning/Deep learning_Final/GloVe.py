# -*- coding: utf-8 -*-
"""
Created on Mon Jan 14 16:16:16 2019

@author: 藍國瑞
"""

import numpy as np

# Category -> words
data = {
  'Names': ['john','jay','dan','nathan','bob'],
  'Colors': ['yellow', 'red','green'],
  'Places': ['tokyo','bejing','washington','mumbai'],
}
# Words -> category
categories = {word: key for key, words in data.items() for word in words}

# Load the whole embedding matrix
embeddings_index = {}
with open('glove.6B.100d.txt',encoding = 'utf8') as f:
  for line in f:
    values = line.split()
    word = values[0]
    embed = np.array(values[1:], dtype=np.float32)
    embeddings_index[word] = embed
print('Loaded %s word vectors.' % len(embeddings_index))
# Embeddings for available words
data_embeddings = {key: value for key, value in embeddings_index.items() if key in categories.keys()}

# Processing the query
def process(query):
  query_embed = embeddings_index[query]
  scores = {}
  for word, embed in data_embeddings.items():
    category = categories[word]
    dist = query_embed.dot(embed)
    dist /= len(data[category])
    scores[category] = scores.get(category, 0) + dist
  return scores

# Testing
print(process('pink'))
print(process('frank'))
print(process('moscow'))














