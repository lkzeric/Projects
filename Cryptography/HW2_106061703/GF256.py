# -*- coding: utf-8 -*-
"""
Created on Sat Apr 21 13:04:16 2018

@author: 106061703 藍國瑞
"""

import itertools

N=8
mx='00011011' #ireducible polynomial

def GF256_add (a,b):
    output=[0 for i in range(N)]
    for i in range(N):
        output[i] = int(a[i]) ^ int( b[i])
    return list_to_string(output)

#test:a=GF256_add('11011100','10001101')
        
def GF256_mult_x (a,mx):
    output=[0 for i in range(N)]
    temp=[0 for i in range(N)]
    a=list(a)
    if int(a[0])==0:
        for i in range(N-1):
            output[i] = int(a[i+1])
        output[7] = 0
            
    else:
        for i in range(N-1):
            temp[i] = int(a[i+1])
        temp[7] = 0
        output = GF256_add(temp,mx)
    return list_to_string(output)
    
        
##test:b=GF256_mult_x('01100010',mx)          
        
def GF256_mult (a,b):
    output=[0 for i in range(N)]
    a=list(a)
    b_list = list(b)
    for i in range(N):
        temp = a
        if int(b_list[i])!=0:
            for j in range(1,N-i):
                 temp = GF256_mult_x(temp,mx)
            output = GF256_add(output,temp)
        
        else:
            pass
    return list_to_string(output)

##test:c=GF256_mult('00001101','00000111')


def GF256_inv(a, mx):  
    lst = list(itertools.product([0, 1], repeat = N))
    for poly in lst:
        poly = list_to_string(poly)
        temp = GF256_mult(a, poly)
        num = shifting(temp)
        if num == 1:
            return poly
    return '00000000'
 
################ extra functions #############
def shifting(bitlist):
    bitlist = list(bitlist)
    out = 0
    for bit in bitlist:
        out = (out << 1) | int(bit)
    return out

    
    
def list_to_string (a):
    output = ''
    for i in range(len(a)):
        
        output += str(a[i])
    
    return output

        
    




