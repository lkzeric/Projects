"""
Created on Sat Apr 21 16:16:34 2018

@author: 106061703 藍國瑞
"""
import AES



print('Implement the Advanced Ecryption Standard(AES)')

mode= input('Choose mode (Encryption / Decryption):')

if mode=='Encryption':
    plaintext = input("Please enter the plaintext:")
    key = input("Please enter the key:")
    AES.Encryption(plaintext,key)

elif mode=='Decryption':
    ciphertext = input("Please enter the ciphertext:")
    key = input("Please enter the key:")
    AES.Decryption(ciphertext,key)

