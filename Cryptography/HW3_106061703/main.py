# -*- coding: utf-8 -*-
"""
Created on Tue May 15 08:17:30 2018

@author: 106061703 藍國瑞
"""


import Miller_primality
import Rabin_crypt



def non_space(str):
    output = str.replace(' ','')
    return output


def add_space(string):
    string = string[::-1]
    string = ' '.join(string[8*i: 8*i + 8] for i in range(0, 8))
    return string[::-1]
    
                      
if __name__ == '__main__':
   
    ## Miller-Rabin
    print('<Miller-Rabin>')
    print(add_space('{:x}'.format(Miller_primality.generate_prime_number(256))))
    
    ## Rabin Encryption
    print('<Rabin Encryption>')
    p = int(non_space(input('p =')),16) #transform from base_16 to base_10
    
    q = int(non_space(input('q =')),16) #transform from base_16 to base_10
    n = p*q #base_10
    
    print('n = pq =', add_space('{:x}'.format(n)))   #transform from base_10 to base_16 by 'format'
    plaintext = int(non_space(input('plaintext =')),16)  #transform from base_16 to base_10
    ciphertext = Rabin_crypt.encrypt(plaintext , n)
    print('ciphertext = ',add_space('{:x}'.format(ciphertext))) #transform from base_10 to base_16 by 'format'
 
    ## Rabin Decryption
    print('<Rabin Decryption>')
    ciphertext = int(non_space(input('ciphertext =')),16)
    
    print('Private Key:')
    p = int(non_space(input('p =')),16)
    q = int(non_space(input('q =')),16)
    plaintext = Rabin_crypt.decrypt(ciphertext , p , q)
    print('plaintext = ',add_space('{:x}'.format(plaintext).zfill(224//4)))  #transform from base_10 to base_16 by 'format'
  
    
    
 
    