# -*- coding: utf-8 -*-
"""
Created on Sat Apr 21 16:49:57 2018

@author: 106061703 藍國瑞
"""

import GF256

key_size = 16  # bytes, 128 bits, 32 nibbles
plaintext_block_size = 16  # in bytes, 128 bits, 32 nibbles
ciphertext_block_size = 16  # in bytes, 128 bits, 32 nibbles
round_key_size = 16  # bytes, 128 bits, 32 nibbles
expanded_key_size = 176  # bytes
Nr = 10  # num of rounds
Nb = 4  # 4 * 4 * 8 = 128 bits
Nk = 4  # 4 * 4 * 8 = 128 bits
shift=[0,1,2,3]




###### affine_transformation ######
affine_transformation_matrix = [[1, 0, 0, 0, 1, 1, 1, 1],
                                [1, 1, 0, 0, 0, 1, 1, 1],
                                [1, 1, 1, 0, 0, 0, 1, 1],
                                [1, 1, 1, 1, 0, 0, 0, 1],
                                [1, 1, 1, 1, 1, 0, 0, 0],
                                [0, 1, 1, 1, 1, 1, 0, 0],
                                [0, 0, 1, 1, 1, 1, 1, 0],
                                [0, 0, 0, 1, 1, 1, 1, 1]]
inverse_affine_transformation_matrix = [[0, 0, 1, 0, 0, 1, 0, 1],
                                        [1, 0, 0, 1, 0, 0, 1, 0],
                                        [0, 1, 0, 0, 1, 0, 0, 1],
                                        [1, 0, 1, 0, 0, 1, 0, 0],
                                        [0, 1, 0, 1, 0, 0, 1, 0],
                                        [0, 0, 1, 0, 1, 0, 0, 1],
                                        [1, 0, 0, 1, 0, 1, 0, 0],
                                        [0, 1, 0, 0, 1, 0, 1, 0]]

affine_transformation_add = [1,1,0,0,0,1,1,0]

inverse_affine_transformation_add = [0,1,1,0,0,0,1,1]
###### Mix_columns ######

mix_column_matrix=[['00000010','00000011','00000001','00000001'],
                   ['00000001','00000010','00000011','00000001'],
                   ['00000001','00000001','00000010','00000011'],
                   ['00000011','00000001','00000001','00000010']]


inverse_mix_column_matrix=[['00001110','00001011','00001101','00001001'],
                       ['00001001','00001110','00001011','00001101'],
                       ['00001101','00001001','00001110','00001011'],
                       ['00001011','00001101','00001001','00001110']]

###### key expansion #####

RC=['00000001','00000010','00000100','00001000','00010000','00100000','01000000','10000000','00011011','00110110']                                               

#####################################################
def Encryption(plaintext,key):
    ### transform the hex into binary
    plaintext_binary_str = bin(int(plaintext,16))[2:].zfill(plaintext_block_size*8)
    key_binary_str = bin(int(key,16))[2:].zfill(key_size*8)
    
    plaintext_divided_list = [plaintext_binary_str[ 8*i : (8*i)+8] for i in range(plaintext_block_size)]
    plaintext_block = [["" for i in range(0, 4)] for j in range(0, 4)]
    key_divided_list =[ key_binary_str[ 8*i : (8*i)+8] for i in range(key_size)]
    key_block = [["" for i in range(0, 4)] for j in range(0, 4)]
    
    
    
    
    ### insert the plaintext into the 4*4 matrix
    for i in range(4):
        for j in range(4):
            plaintext_block[i][j] = plaintext_divided_list[i+4*j] ##each element in the matrix is string, [['a','b'],['c','d']]
            
    ### insert the key into the 4*4 matrix
    for i in range(4):
        for j in range(4):
            key_block[i][j] = key_divided_list[i+4*j] ##each element in the matrix is matrix is string, [['a','b'],['c','d']]
    
    ### 0th_Add round key
    
    for i in range(4):
        for j in range(4):
            plaintext_block[i][j] = XOR(plaintext_block[i][j] , key_block[i][j])
    
    zero_plaintext = ''
    for i in range(4):
        for j in range(4):
            zero_plaintext += ' '+binary_to_hex(plaintext_block[j][i])
           
    print('SE',0,':',zero_plaintext)
 
    expansion_key = key_expansion(key_block) #it is only relative to the set of the key
    
    
    ### Encryption 10 rounds(0~9)
    for r in range(0,Nr):   #NR=10
        ### ByteSub
        for i in range(4):
            for j in range(4):
                plaintext_block[i][j] = bytesub(plaintext_block[i][j])

        ### ShiftRow
        for j in range(4):
            plaintext_block[j] = plaintext_block[j] [shift[j]:] + plaintext_block[j] [:shift[j]]
   
        ### Mixcolumn except 9th round #0~8
        if r<Nr-1:
            plaintext_block = mixcolumn(plaintext_block)
        ### AddRoundKey
        for i in range(4):
            for j in range(4):
                plaintext_block[i][j] = XOR(plaintext_block[i][j] , expansion_key[r+1][i][j])
                
        if r<9:
            ciphertext_mid = ''
            for i in range(4):
                for j in range(4):
                    ciphertext_mid += ' '+binary_to_hex(plaintext_block[j][i])
            print('SE',r+1, ':',ciphertext_mid)
  
        if r==9:
            ciphertext_mid = ''
            for i in range(4):
                for j in range(4):
                    ciphertext_mid += ' '+binary_to_hex(plaintext_block[j][i])
            print('Ciphertext:',ciphertext_mid)
       
        
        
        
    ### End of the rounds
     

    

    ciphertext = ''
    for i in range(4):
        for j in range(4):
            ciphertext += binary_to_hex(plaintext_block[j][i])

    return ciphertext
    
    
    
######################################
def Decryption(ciphertext , key) :
    ciphertext_binary_str = bin(int(ciphertext,16))[2:].zfill(ciphertext_block_size*8)
    key_binary_str = bin(int(key,16))[2:].zfill(key_size*8)
    
    ciphertext_divided_list = [ciphertext_binary_str[ 8*i : (8*i)+8] for i in range(ciphertext_block_size)]
    ciphertext_block = [["" for i in range(0, 4)] for j in range(0, 4)]
    key_divided_list =[ key_binary_str[ 8*i : (8*i)+8] for i in range(key_size)]
    key_block = [["" for i in range(0, 4)] for j in range(0, 4)]
    
    
    
    
    ### insert the ciphertext into the 4*4 matrix
    for i in range(4):
        for j in range(4):
            ciphertext_block[i][j] = ciphertext_divided_list[i+4*j] ##each element in the matrix is string, [['a','b'],['c','d']]
            
    ### insert the key into the 4*4 matrix
    for i in range(4):
        for j in range(4):
            key_block[i][j] = key_divided_list[i+4*j] ##each element in the matrix is matrix is string, [['a','b'],['c','d']]
    
    expansion_key = key_expansion(key_block)
    ### add round key in the decryption , 
    ### add the ciphertext and the 10th set of the expasion key
    for i in range(4):
        for j in range(4):
            ciphertext_block[i][j] = XOR(ciphertext_block[i][j], expansion_key[10][i][j])
            
    zero_ciphertext = ''
    for i in range(4):
        for j in range(4):
            zero_ciphertext += ' '+ binary_to_hex(ciphertext_block[j][i])
           
    print('SD' ,0,':',zero_ciphertext)        
    ### Decryption 10 rounds(0~9)
    for i in range(9, -1, -1):
        ### inverse shift rows
        for j in range(4):
            ciphertext_block[j] = ciphertext_block[j][4 - shift[j]:] + ciphertext_block[j][:4 - shift[j]]

        ### inverse ByteSub
        for j in range(4):
            for k in range(4):
                ciphertext_block[j][k] = inverse_ByteSub(ciphertext_block[j][k])

        ### add round keys
        for j in range(4):
            for k in range(4):
                ciphertext_block[j][k] = XOR(ciphertext_block[j][k], expansion_key[i][j][k])

        ### inverse MixColumn (only for the first 9 iteration)
        if i > 0:
            ciphertext_block = inverse_MixColumn(ciphertext_block)
        
        
    
        if i>0:
            
            plaintext_mid = ''
            for h in range(4):
                for j in range(4):
                    plaintext_mid += ' '+binary_to_hex(ciphertext_block[j][h])
            print('SD',10-i, ':',plaintext_mid)
  
        if i==0:
            plaintext_mid = ''
            for i in range(4):
                for j in range(4):
                    plaintext_mid += ' '+binary_to_hex(ciphertext_block[j][i])
            print('Plaintext:',plaintext_mid)
    
    
    
    
    
    
    
    ### End of the rounds

    plaintext = ''
    for i in range(4):
        for j in range(4):
            plaintext += binary_to_hex(ciphertext_block[j][i])

    return plaintext
    
    
######################### AES functions #######################

    

### XOR
    
def XOR(a,b):
    output=[0 for i in range(8)]
    for i in range(8):
        output[i]= int(a[i]) ^int( b [i])
    return GF256.list_to_string(output)
### bytesub
def bytesub(a):
    temp = [0 for i in range(8)]
    for i in range(8):
        temp[i] =a[i]
    temp_str = GF256.list_to_string(temp)
    ### GF(256) inverse
    inv = GF256.GF256_inv(temp_str , GF256.mx)
    ### Affine mapping
    output=[0 for i in range(8)]
    for i in range(0, 8):  
        flag = 0
        for j in range(0, 8):
            flag ^= (int(inv[7-j]) * affine_transformation_matrix[i][j])
        output[7-i] = flag
    for i in range(0, 8):
        output[i] = output[i] ^ affine_transformation_add[7-i]

    # convert a list to a string
    return GF256.list_to_string(output)


### inverse bytesub
def inverse_ByteSub(a):
    temp = XOR(a, inverse_affine_transformation_add)

    output = [0 for i in range(0, GF256.N)]
    # matrix multiplication
    for i in range(0, GF256.N):
        flag = 0
        for j in range(0, GF256.N):
            flag ^= (int(temp[7-j]) * inverse_affine_transformation_matrix[i][j])
        output[7-i] = flag
    # find inverse of output
    inv = GF256.GF256_inv(output, GF256.mx)

    # convert a list to a string
    return GF256.list_to_string(inv)


### mixcolumn

def mixcolumn(a):
    output = [['' for i in range(0, 4)] for j in range(0, 4)] 
    for i in range(0, 4):
        for j in range(0, 4):
            temp = '00000000'  # temp is a 8-bit string

            for k in range(0, 4):
                
                temp = GF256.GF256_add(temp, GF256.GF256_mult(mix_column_matrix[i][k], a[k][j]))

            output[i][j] = temp

    return output

### inverse mixcolumn

def inverse_MixColumn(bytes_2d):
    output = [['' for i in range(0, 4)] for j in range(0, 4)]   # output is a 4 x 4 matrix that contains strings

    for i in range(0, 4):
        for j in range(0, 4):
            temp = '00000000'  # temp is a 8-bit string

            for k in range(0, 4):
                temp = GF256.GF256_add(temp, GF256.GF256_mult(inverse_mix_column_matrix[i][k], bytes_2d[k][j]))

            output[i][j] = temp

    return output


### key expansion
def key_expansion(key_block):
    # There are 11 sets of key
    expanded_key_3d = [[['' for i in range(4)]for j in range(4)]for k in range(0, 11)]
    # the first key(0th) is the initialized key
    for i in range(4):
        for j in range(4):
            expanded_key_3d[0][i][j] = key_block[i][j]

    # generate the rest of the keys(1st~10th)
    for i in range(1, 11):
        # generate the rightmost column(a list of strings)
        rightmost_column = ['' for i in range(4)]
        # assign the last round to the current column
        for j in range(4):
            rightmost_column[j] = expanded_key_3d[i - 1][j][3]

        # 1. RotWord 
        rightmost_column = rightmost_column[1:] + rightmost_column[:1]

        # 2. SubWord
        for j in range(0, 4):
            rightmost_column[j] = bytesub(rightmost_column[j])

        # 3. XOR with Rcon (actually only have to xor the first byte)
        rightmost_column[0] = XOR(rightmost_column[0], RC[i - 1])

        # 4. ADD
        # first, create the leftmost column in the next round
        for j in range(4):
            expanded_key_3d[i][j][0] = XOR(expanded_key_3d[i - 1][j][0], rightmost_column[j])
        # second
        for k in range(1, 4):
            for j in range(0, 4):
                expanded_key_3d[i][j][k] = XOR(expanded_key_3d[i - 1][j][k], expanded_key_3d[i][j][k - 1])

    return expanded_key_3d


    
    
    
    
    
### binary to hex
    
def binary_to_hex (a):
    return str(hex(int(a, 2)))[2:].zfill(2)
   


def print_2d_matrix(matrix_2d):
    # print('bytes_2d : ')
    for i in range(0, 4):
        print(matrix_2d[i][0], matrix_2d[i][1], matrix_2d[i][2], matrix_2d[i][3])
    return




