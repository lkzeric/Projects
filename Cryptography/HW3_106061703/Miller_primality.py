# -*- coding: utf-8 -*-
"""
Created on Tue May 15 10:44:06 2018

@author: 106061703 藍國瑞
"""

import random
primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97,
          101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197,
          199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313,
          317, 331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431, 433, 439,
          443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503, 509, 521, 523, 541, 547, 557, 563, 569, 571,
          577, 587, 593, 599, 601, 607, 613, 617, 619, 631, 641, 643, 647, 653, 659, 661, 673, 677, 683, 691,
          701, 709, 719, 727, 733, 739, 743, 751, 757, 761, 769, 773, 787, 797, 809, 811, 821, 823, 827, 829,
          839, 853, 857, 859, 863, 877, 881, 883, 887, 907, 911, 919, 929, 937, 941, 947, 953, 967, 971, 977,
          983, 991, 997]

def prime_ornot(num):
    # 1. factorize n-1 = m*2^k
    k=0
    temp = num-1
    while(temp%2 == 0):
        temp = temp//2
        k += 1
    else:
        m=temp
    
    # 2. Primality test
    
    for a in primes:
        y = [pow(a , m*(2**i) , num) for i in range (0,k)]
        if pow(a , m, num ) !=1 and none_in_y_is_n(y,num-1):
            return False # it means composite
        elif  pow(a , m , num) == 1 or not none_in_y_is_n(y,num-1):
            continue
    return True # it means prime (have to test all the primes)
        
        
def generate_prime_number (number_of_bits):
    dd = True
    while (dd == True):
        prime_number = random.getrandbits(number_of_bits)
        if (prime_ornot(prime_number) ==  True):
            dd = False
        else:
            dd = True
    return prime_number
        
def none_in_y_is_n (y,n):
    for i in y:
        if i==n:
            return False
    return True
    
    
