# -*- coding: utf-8 -*-
"""
Created on Tue May 15 10:44:07 2018

@author: 106061703 藍國瑞
"""


def padding(m):
    temp = bin(m)[2:] #should be padded in base_2
    output = temp + temp[-16:]
    return int(output,2) #transform from base_2 to base_10

def encrypt(plaintext , n):
    ciphertext = pow(padding(plaintext) , 2 , n)
    return ciphertext #base_10

def decrypt(a,p,q):
    n = p*q
    r=0
    s=0
    
    # sqroot of a mod p
    if p%4 ==3:
        r=sqroot_of_3_mod_4(a,p)
    elif p%8 ==5:
        r=sqroot_of_5_mod_8(a,p)
    # sqroot of a mod q
    if q%4 ==3:
        s=sqroot_of_3_mod_4(a,q)
    elif p%8 ==5:
        s=sqroot_of_5_mod_8(a,q)
        
    gcd,c,d = xggt(p,q)
    
    x=(r*d*q+s*c*p) %n
    y=(r*d*q-s*c*p) %n
    
    ans=[x,n-x,y,n-y]  # 4 possible answers
    plaintext_temp = decide(ans)
    plaintext_original = (bin(plaintext_temp))[:-16]
    plaintext = int(plaintext_original,2)
  
    return plaintext
    
    

#Legendre symbol
def lengedre(a,p):
    return pow(a , (p-1)/2 , p)

#find sqroot in Zp where p=3 mod 4
def sqroot_of_3_mod_4(a,p):
    r=pow(a, (p+1)//4 , p)
    return r

#find sqroot in Zp where p=5 mod 8
def sqroot_of_5_mod_8(a,p):
    d=pow(a, (p-1)//4 , p)
    if d==1:
        r=pow(a, (p+3)//8 , p)
        return r
    elif d==p-1:
        r = (2*a*pow(4*a , (p-5)//8 , p)) %p
        return r

#extended Euclid's algorithm
def xggt(num_1, num_2):

    if num_1 % num_2 == 0:
        return(num_2, 0, 1)
    else:
        gcd, lin_fact_1, lin_fact_2 = xggt(num_2, num_1 % num_2)

        lin_fact_1 = lin_fact_1 - num_1 // num_2 * lin_fact_2

        return(gcd, lin_fact_2, lin_fact_1)
        
#decide which the answer is
def decide(ans):
    for i in ans:
        temp = bin(i)
        if  temp[-32:-16] == temp[-16:]:
            return i
       

        
        
        
        
        
        