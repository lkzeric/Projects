import polar_codes
import CRC
import numpy as np
import tensorflow as tf
import matplotlib.pyplot as plt
import winsound
duration = 500  # millisecond
freq = 440  # Hz

np.set_printoptions(edgeitems=100000, linewidth=100000)
np.set_printoptions(threshold=np.nan)

############### Neural CRC Codes PARAMETERS ###############
N_codewords = 12800
BATCH_SIZE = 128
TOTAL_BATCH_NUM = N_codewords // BATCH_SIZE

N_epochs = 60
learning_rate = 0.0002

N_polar = 1024        # code length
overall_R = 0.5     # code rate
polar_iter_num = 60
Ex_BP_num = 120
stage_num = 2

CRC_bit_num = 16
CRC_poly = np.array([1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1])
CRC_iter_num = 5

SNR_in_db = 1.5

n = int(np.log2(N_polar))
N_message = int(N_polar * overall_R)
N_message_polar = N_message + CRC_bit_num

polar_R = N_message_polar / N_polar
epsilon = polar_codes.find_epsilon(SNR_in_db, polar_R)   # cross-over probability for the BEC

benchmark = 3048249
BIG_NUM = 100
DIV = 500

initial_alpha = 1
initial_beta = 0.04
initial_threshold = 5

alpha_c=tf.constant(1)
beta_c=tf.constant(0.04)
threshold_c=tf.constant(5)








tanh_height = 10
tanh_width = 10000
######################################################
Var = 1 / (2 * polar_R * pow(10.0, SNR_in_db / 10.0))
sigma = pow(Var, 1 / 2)

# Polar Code Components
B_N = polar_codes.permutation_matrix(N_polar)
frozen_indexes = polar_codes.generate_frozen_set_indexes(N_polar, polar_R, epsilon)  # datatype: list
info_indexes = [i for i in range(N_polar) if i not in frozen_indexes]
G_polar = polar_codes.generate_G_N(N_polar)
interlacer = polar_codes.generate_interlacer_matrix(N_polar)
dec_interleaver = polar_codes.generate_decision_llr_interleaver(N_polar, frozen_indexes, info_indexes)

# CRC
G_CRC = CRC.generate_G(N_message, CRC_bit_num, CRC_poly)
G_CRC_systematic = CRC.to_systematic_G(N_message, G_CRC)
H = CRC.generate_H(G_CRC_systematic, N_message_polar, N_message)

CN_num = H.shape[0]
VN_num = H.shape[1]
total_elements = CN_num * VN_num  # Total nodes in a hidden layer

print('SNR:', SNR_in_db, 'db')
print('Polar Code Rate:', polar_R)
print('Epsilon:', epsilon)
print('Initial Alpha:', initial_alpha)
print('Initial Beta:', initial_beta)
print('Initial Threshold:', initial_threshold, '\n')

print('N message polar:', N_message_polar)
print('Polar Code Rate:', polar_R)
print('CRC bit num:', CRC_bit_num)
print('CRC polynomial:', CRC_poly)
print('N message:', N_message, '\n')
print('Info Indexes length:', info_indexes.__len__())

print('tanh height:', tanh_height)
print('tanh width:', tanh_width)


def forwardprop(x, alpha_1_up, beta_1_up, threshold_1_up,alpha_1_low, beta_1_low, threshold_1_low,
                     alpha_2_up, beta_2_up, threshold_2_up,alpha_2_low, beta_2_low, threshold_2_low):

    polar_decoded_llr = Ex_polar_decoder(x, alpha_1_up, beta_1_up, threshold_1_up,alpha_1_low, beta_1_low, threshold_1_low,
                                         alpha_2_up, beta_2_up, threshold_2_up,alpha_2_low, beta_2_low, threshold_2_low, a_priori=None)
    polar_decoded_llr_scaled = sim_sign(polar_decoded_llr)

    y_hat = tf.negative(polar_decoded_llr_scaled[:, :N_message])

    return y_hat


def Ex_polar_decoder(x, alpha_1_up, beta_1_up, threshold_1_up,alpha_1_low, beta_1_low, threshold_1_low,
                     alpha_2_up, beta_2_up, threshold_2_up,alpha_2_low, beta_2_low, threshold_2_low,a_priori=None):
    channel_LLR = 2 * x / np.power(sigma, 2)  # the shape should be: (batch_size, N_Polar)

    ############################# Polar ####################################
    # The list of all hidden layers
    Polar_hidden_layers = []

    if a_priori is not None:
        frozen_llr = tf.ones(shape=(BATCH_SIZE, len(frozen_indexes)), dtype=tf.float64) * BIG_NUM
        LLR_R_tensor = tf.concat([frozen_llr, a_priori], axis=1)
        LLR_R_tensor = tf.matmul(LLR_R_tensor, dec_interleaver)
    else:
        # Initialize decision_LLR
        LLR_R = np.zeros((BATCH_SIZE, N_polar), dtype=np.float64)

        for i in frozen_indexes:
            LLR_R[:, i] = BIG_NUM

        LLR_R_tensor = tf.convert_to_tensor(LLR_R) # convert to the value that can be used in the tensorflow

    decision_LLR = tf.matmul(LLR_R_tensor, B_N)

    # decision_LLR = tf.constant(LLR_permuted, dtype=tf.float64)
    N_2_zeros = tf.zeros(shape=(BATCH_SIZE, N_polar // 2), dtype=tf.float64)
    weight_counter = 0

    #####################################################
    ############## The first R Propagation ##############
    # The first R hidden layer, so take decision_LLR as an input, and view L as 0
    cur_idx = 0
    print('R Layer :', cur_idx)
    upper = f(decision_LLR[:, : N_polar // 2], decision_LLR[:, N_polar // 2:] + N_2_zeros)
    lower = f(N_2_zeros, decision_LLR[:, : N_polar // 2]) + decision_LLR[:, N_polar // 2:]
    previous_layer = interlace(upper, lower)
    Polar_hidden_layers.append(previous_layer)

    # Not the first R hidden layer, so take the previous layers as inputs and view L as 0
    for i in range(n - 2):
        cur_idx += 1
        print("R Layer :", cur_idx)
        upper = f(previous_layer[:, : N_polar // 2], previous_layer[:, N_polar // 2:] + N_2_zeros)
        lower = f(N_2_zeros, previous_layer[:, : N_polar // 2]) + previous_layer[:, N_polar // 2:]
        previous_layer = interlace(upper, lower)
        Polar_hidden_layers.append(previous_layer)
    #####################################################
    #####################################################


    #####################################################
    #####################################################
    # Run through 'iter_num' times.
    # Each iteration consists of 1 full L propagation and 1 full R propagation.
    for k in range(polar_iter_num - 1):
        ###### L Propagation
        # The first L propagation layer.
        cur_idx += 1
        print("L Layer :", cur_idx)
        upper = f(channel_LLR[:, : N_polar: 2], channel_LLR[:, 1: N_polar: 2] + previous_layer[:, N_polar // 2:])
        lower = f(previous_layer[:, : N_polar // 2], channel_LLR[:, : N_polar: 2]) + channel_LLR[:, 1: N_polar: 2]
        ###### Neural Ex-BP #######################################################################################
        if weight_counter < Ex_BP_num:
            print('Ex-BP layer')
            upper = (upper*alpha_c + previous_layer[:, :N_polar // 2] * beta_c * \
                    sim_step(tf.abs(previous_layer[:, :N_polar // 2]) - threshold_c )+ \
                    upper * (1 - sim_step(tf.abs(previous_layer[:, :N_polar // 2]) - threshold_c)))
            lower = (lower*alpha_c + previous_layer[:, N_polar // 2:] * beta_c * \
                    sim_step(tf.abs(previous_layer[:, N_polar // 2:]) - threshold_c) + \
                    lower * (1 - sim_step(tf.abs(previous_layer[:, N_polar // 2:]) - threshold_c)))
            weight_counter += 1
        ###########################################################################################################
        previous_layer = concatenate(upper, lower)
        Polar_hidden_layers.append(previous_layer)

        # Not the first L propagation layer.
        for i in range(n - 2):
            cur_idx += 1
            print("L Layer :", cur_idx)
            corresponding_R_idx = cur_idx - (2 * i + 3)
            corresponding_R_layer = Polar_hidden_layers[corresponding_R_idx]
            upper = f(previous_layer[:, : N_polar: 2], previous_layer[:, 1: N_polar: 2] + corresponding_R_layer[:, N_polar // 2:])
            lower = f(corresponding_R_layer[:, : N_polar // 2], previous_layer[:, : N_polar: 2]) + previous_layer[:, 1: N_polar: 2]

            if (stage_num - i - 1) >= 1:
                ###### Neural Ex-BP #######################################################################################
                if weight_counter < Ex_BP_num:
                    print('Ex-BP layer')
                    upper = (upper*alpha_c + previous_layer[:, :N_polar // 2] * beta_c * \
                             sim_step(tf.abs(previous_layer[:, :N_polar // 2]) - threshold_c )+ \
                             upper * (1 - sim_step(tf.abs(previous_layer[:, :N_polar // 2]) - threshold_c)))
                    lower = (lower*alpha_c + previous_layer[:, N_polar // 2:] * beta_c * \
                             sim_step(tf.abs(previous_layer[:, N_polar // 2:]) - threshold_c) + \
                             lower * (1 - sim_step(tf.abs(previous_layer[:, N_polar // 2:]) - threshold_c)))
                    weight_counter += 1
                ###########################################################################################################
            previous_layer = concatenate(upper, lower)
            Polar_hidden_layers.append(previous_layer)


        ###### R Propagation
        # The first R propagation layer.
        cur_idx += 1
        print("R Layer :", cur_idx)
        upper = f(decision_LLR[:, : N_polar // 2], decision_LLR[:, N_polar // 2:] + previous_layer[:, 1: N_polar: 2])
        lower = f(previous_layer[:, : N_polar: 2], decision_LLR[:, : N_polar // 2]) + decision_LLR[:, N_polar // 2:]
        previous_layer = interlace(upper, lower)
        Polar_hidden_layers.append(previous_layer)

        # Not the first R propagation layer.
        for i in range(n - 2):
            cur_idx += 1
            print("R Layer :", cur_idx)
            corresponding_L_idx = cur_idx - (2 * i + 3)
            corresponding_L_layer = Polar_hidden_layers[corresponding_L_idx]
            upper = f(previous_layer[:, : N_polar // 2], previous_layer[:, N_polar // 2:] + corresponding_L_layer[:, 1: N_polar: 2])
            lower = f(corresponding_L_layer[:, : N_polar: 2], previous_layer[:, : N_polar // 2]) + previous_layer[:, N_polar // 2:]
            previous_layer = interlace(upper, lower)
            Polar_hidden_layers.append(previous_layer)

    # The last full L propagation. Need to do 1 more time.
    cur_idx += 1
    print("L Layer :", cur_idx)
    upper = f(channel_LLR[:, : N_polar: 2], channel_LLR[:, 1: N_polar: 2] + previous_layer[:, N_polar // 2:])
    lower = f(previous_layer[:, : N_polar // 2], channel_LLR[:, : N_polar: 2]) + channel_LLR[:, 1: N_polar: 2]
    ###### Neural Ex-BP #######################################################################################
    if weight_counter < Ex_BP_num:
        print('Neural Ex-BP layer')
        upper = (upper * alpha_1_up + previous_layer[:, :N_polar // 2] * beta_1_up * \
                sim_step(tf.abs(previous_layer[:, :N_polar // 2]) - threshold_1_up) + \
                upper * (1 - sim_step(tf.abs(previous_layer[:, :N_polar // 2]) - threshold_1_up )))
        lower = (lower * alpha_1_low + previous_layer[:, N_polar // 2:] * beta_1_low * \
                sim_step(tf.abs(previous_layer[:, N_polar // 2:]) - threshold_1_low) + \
                lower * (1 - sim_step(tf.abs(previous_layer[:, N_polar // 2:]) - threshold_1_low)))
        weight_counter += 1
    ###########################################################################################################
    previous_layer = concatenate(upper, lower)
    Polar_hidden_layers.append(previous_layer)

    # Not the first L propagation layer.
    for i in range(n - 2):
        cur_idx += 1
        print("L Layer :", cur_idx)
        corresponding_R_idx = cur_idx - (2 * i + 3)
        corresponding_R_layer = Polar_hidden_layers[corresponding_R_idx]
        upper = f(previous_layer[:, : N_polar: 2], previous_layer[:, 1: N_polar: 2] + corresponding_R_layer[:, N_polar // 2:])
        lower = f(corresponding_R_layer[:, : N_polar // 2], previous_layer[:, : N_polar: 2]) + previous_layer[:, 1: N_polar: 2]

        if (stage_num - i - 1) >= 1:
            ###### Neural Ex-BP #######################################################################################
            if weight_counter < Ex_BP_num:
                print('Neural Ex-BP layer')
                upper = (upper * alpha_2_up + previous_layer[:, :N_polar // 2] * beta_2_up * \
                          sim_step(tf.abs(previous_layer[:, :N_polar // 2]) - threshold_2_up) + \
                          upper * (1 - sim_step(tf.abs(previous_layer[:, :N_polar // 2]) - threshold_2_up )))
                lower = (lower * alpha_2_low + previous_layer[:, N_polar // 2:] * beta_2_low * \
                         sim_step(tf.abs(previous_layer[:, N_polar // 2:]) - threshold_2_low) + \
                         lower * (1 - sim_step(tf.abs(previous_layer[:, N_polar // 2:]) - threshold_2_low)))
                weight_counter += 1
            ###########################################################################################################
        previous_layer = concatenate(upper, lower)
        Polar_hidden_layers.append(previous_layer)

    # This is for the output layer.
    cur_idx += 1
    print("Output Layer :", cur_idx)
    upper = f(previous_layer[:, : N_polar: 2], previous_layer[:, 1: N_polar: 2] + decision_LLR[:, N_polar // 2:])
    lower = f(decision_LLR[:, : N_polar // 2], previous_layer[:, : N_polar: 2]) + previous_layer[:, 1: N_polar: 2]
    previous_layer = concatenate(upper, lower)
    Polar_hidden_layers.append(previous_layer)
    #####################################################
    #####################################################

    # Take the last hidden layer as the output layer.
    polar_output_layer = Polar_hidden_layers[-1]
    polar_output_layer = tf.matmul(polar_output_layer, B_N)

    # Only take the information bit indexes.
    polar_output_llr = tf.gather(polar_output_layer, info_indexes, axis=1)

    return polar_output_llr




def sim_step(x):  #prevent the gradient vanishment
    return (tf.tanh(10000 * x) + 1) / 2


def sim_sign(x): #set the upper and lower bound of the LLR value
    return tanh_height * tf.tanh(x / tanh_width)


# Min-Sum Algorithm
def f(x, y):
    sign = tf.multiply(tf.sign(x), tf.sign(y))
    minimum = tf.minimum(tf.abs(x), tf.abs(y))
    return tf.multiply(sign, minimum)


def interlace(a, b):
    output = tf.concat([a, b], axis=1)
    return tf.matmul(output, interlacer)


def concatenate(a, b):
    return tf.concat([a, b], axis=1)


def min_sum(layer, lst):
    ###### Sign Product part ######
    sign_lst = tf.sign(tf.gather(layer, lst, axis=1))
    sign_prod = tf.reduce_prod(sign_lst, reduction_indices=[1])

    ###### Min Abs part ######
    abs_lst = tf.abs(tf.gather(layer, lst, axis=1))
    min_abs = tf.reduce_min(abs_lst, reduction_indices=[1])

    # The result should still be a (batch_size, 1) tensor
    return sign_prod * min_abs


def summation(layer, lst):
    # Here, "lst" may be an empty list.
    if len(lst) != 0:
        sum_lst = tf.gather(layer, lst, axis=1)
        summ = tf.reduce_sum(sum_lst, reduction_indices=[1])
    else:
        summ = tf.zeros(shape=(BATCH_SIZE,), dtype=tf.float64)

    return summ


def flat_to_2d(index):
    return index // VN_num, index % VN_num


def llr_to_1_0(llr):
    return 1 - ((tf.sign(llr) + 1) // 2)


def add_noise(signal):
    noise = np.random.normal(scale=sigma, size=signal.shape)
    return signal + noise


def make_batch(batch_size):
    message = np.random.randint(2, size=(batch_size, N_message))
    CRC_codeword = CRC.encode(message, G_CRC_systematic)
    message_polar = polar_codes.embed_message(CRC_codeword, batch_size, N_polar, info_indexes)
    polar_codeword = polar_codes.encode(message_polar, G_polar)
    signal = polar_codeword * (-2) + 1
    _x_train = add_noise(signal)
    _y_train = message

    return _x_train, _y_train


if __name__ == '__main__':

    import timeit
    start = timeit.default_timer()

    ###### Variable Initialization ######
    x = tf.placeholder(dtype=tf.float64, shape=(BATCH_SIZE, N_polar), name='x')
    y = tf.placeholder(dtype=tf.float64, shape=(BATCH_SIZE, N_message), name='y')

    # alpha, beta, threshold are the parameters to be trained of the Ex-BP decoder.
    
    '''
    alpha     = [tf.Variable(initial_value=initial_alpha, dtype=tf.float64, name='alpha', trainable=True)
                 for _ in range(Ex_BP_num)]
    beta      = [tf.Variable(initial_value=initial_beta, dtype=tf.float64, name='beta', trainable=True)
                 for _ in range(Ex_BP_num)]
    threshold = [tf.Variable(initial_value=initial_threshold, dtype=tf.float64, name='threshold', trainable=True)
                 for _ in range(Ex_BP_num)]
    print(Ex_BP_num * 3, ' parameters.')
    '''
    
    
    ### Variable for the 1st layer ###
    alpha_1_up=[tf.Variable(initial_value=initial_alpha, dtype=tf.float64, name='alpha_1_up', trainable=True)
                 for _ in range(N_polar/2)]
    
    beta_1_up=[tf.Variable(initial_value=initial_beta, dtype=tf.float64, name='beta_1_up', trainable=True)
                 for _ in range(N_polar/2)]
    
    threshold_1_up=[tf.Variable(initial_value=initial_threshold, dtype=tf.float64, name='threshold_1_up', trainable=True)
                     for _ in range(N_polar/2)]
    
    alpha_1_low=[tf.Variable(initial_value=initial_alpha, dtype=tf.float64, name='alpha_1_low', trainable=True)
                 for _ in range(N_polar/2)]
    
    beta_1_low=[tf.Variable(initial_value=initial_beta, dtype=tf.float64, name='beta_1_low', trainable=True)
                 for _ in range(N_polar/2)]
    
    threshold_1_low=[tf.Variable(initial_value=initial_threshold, dtype=tf.float64, name='threshold_1_low', trainable=True)
                     for _ in range(N_polar/2)]
    
    
    
     ### Variable for the 1st layer ###
    alpha_2_up=[tf.Variable(initial_value=initial_alpha, dtype=tf.float64, name='alpha_2_up', trainable=True)
                 for _ in range(N_polar/2)]
    
    beta_2_up=[tf.Variable(initial_value=initial_beta, dtype=tf.float64, name='beta_2_up', trainable=True)
                 for _ in range(N_polar/2)]
    
    threshold_2_up=[tf.Variable(initial_value=initial_threshold, dtype=tf.float64, name='threshold_2_up', trainable=True)
                     for _ in range(N_polar/2)]
    
    alpha_2_low=[tf.Variable(initial_value=initial_alpha, dtype=tf.float64, name='alpha_2_low', trainable=True)
                 for _ in range(N_polar/2)]
    
    beta_2_low=[tf.Variable(initial_value=initial_beta, dtype=tf.float64, name='beta_2_low', trainable=True)
                 for _ in range(N_polar/2)]
    
    threshold_2_low=[tf.Variable(initial_value=initial_threshold, dtype=tf.float64, name='threshold_2_low', trainable=True)
                     for _ in range(N_polar/2)]
    
    
    
    
    ###### y_hat is a length-N vector. ######
    y_hat = forwardprop(x, alpha_1_up, beta_1_up, threshold_1_up,alpha_1_low, beta_1_low, threshold_1_low,
                        alpha_2_up, beta_2_up, threshold_2_up,alpha_2_low, beta_2_low, threshold_2_low)
    llr = tf.negative(y_hat)

    ###### Cost Function ######
    # penalty to the negative alpha, beta, threshold
    # cost = tf.reduce_sum(tf.nn.sigmoid_cross_entropy_with_logits(labels=y, logits=y_hat)) - \
    #        tf.minimum(tf.reduce_min(alpha), 0) * 1e+10 - \
    #        tf.minimum(tf.reduce_min(beta), 0) * 1e+10 - \
    #        tf.minimum(tf.reduce_min(threshold), 0) * 1e+10
    cost = tf.reduce_sum(tf.nn.sigmoid_cross_entropy_with_logits(labels=y, logits=y_hat))
    error_in_bit = tf.reduce_sum(tf.cast(tf.logical_not(tf.equal(llr_to_1_0(llr), y)), tf.int64))

    ###### Training Operation ######
    update = tf.train.AdamOptimizer(learning_rate).minimize(cost)

    ###### Training ######
    with tf.Session() as sess:
        sess.run(tf.global_variables_initializer())

        print('Total', N_codewords * N_epochs, 'codewords.')
        print('Start training......')

        loss_lst = []
        last_loss = 1e+20

        # Run through N_epochs times.
        for epoch in range(N_epochs):

            print('Epoch: ', epoch + 1, '/', N_epochs)
            total_loss = 0
            total_error = 0

            for batch in range(TOTAL_BATCH_NUM):
                x_train, y_train = make_batch(BATCH_SIZE)
                loss, error, _ = sess.run([cost, error_in_bit, update], feed_dict={x: x_train, y: y_train})
                total_loss += loss
                total_error += error
                print('cost ', batch + 1, '/', TOTAL_BATCH_NUM, ':', loss, ' (accumulated:', total_loss, ')')
            loss_lst.append(total_loss)

            print('Total Loss:', total_loss, 'Last Loss:', last_loss, '. Initial Loss:', benchmark, ', Ratio:', total_loss / benchmark)
            print('BER:', total_error / (BATCH_SIZE * N_polar * TOTAL_BATCH_NUM))

            if total_loss > benchmark * 2:
                loss_lst.pop()
                print('Error Deleted.')

           # print('alpha: ', sess.run(alpha))
           # print('beta: ', sess.run(beta))
           # print('threshold: ', sess.run(threshold), '\n')

            if total_loss < last_loss:
                last_loss = total_loss
            else:
                break

            stop = timeit.default_timer()
            print('Run time :', (stop - start) // 60, 'minutes,', (stop - start) % 60, 'seconds.\n')

        alpha_val = sess.run(alpha)
        print('Trained alpha:', alpha_val)
        beta_val = sess.run(beta)
        print('Trained beta:', beta_val)
        threshold_val = sess.run(threshold)
        print('Trained threshold:', threshold_val)

        # Save the weight for validation.
        np.save('alpha_1024_' + str(N_message_polar) + '_' + str(CRC_bit_num) + '_' + str(int(SNR_in_db * 10)) + '_' + '.npy', alpha_val)
        np.save('beta_1024_' + str(N_message_polar) + '_' + str(CRC_bit_num) + '_' + str(int(SNR_in_db * 10)) + '_' + '.npy', beta_val)
        np.save('threshold_1024_' + str(N_message_polar) + '_' + str(CRC_bit_num) + '_' + str(int(SNR_in_db * 10)) + '_' + '.npy', threshold_val)
        print('Parameters saved.')

        stop = timeit.default_timer()
        print('Run time :', (stop - start) // 60, 'minutes,', (stop - start) % 60, 'seconds')

        print('Lost List:', np.array(loss_lst) / benchmark)

        # Plot the result.
        loss_lst = np.array(loss_lst) / benchmark
        plt.title('Learning Curve')
        plt.plot(loss_lst)
        plt.plot(np.ones(N_epochs))
        plt.savefig('plot_' + str(polar_iter_num) + '.png')
        plt.show()

        ################## Validating ##################
        N_codewords_val = 128000
        BATCH_SIZE_val = 128
        TOTAL_BATCH_NUM_val = N_codewords_val // BATCH_SIZE_val

        N_epochs_val = 1

        print('Start Validating......')
        for epoch in range(N_epochs_val):

            total_err_val = 0
            total_loss_val = 0
            print('Epoch: ', epoch + 1, '/', N_epochs_val)

            for batch in range(TOTAL_BATCH_NUM_val):
                x_train, y_train = make_batch(BATCH_SIZE_val)
                loss, err = sess.run([cost, error_in_bit], feed_dict={x: x_train, y: y_train}) #not run the optimizer, the coefficient keep the same as the training stage
                total_loss_val += loss
                total_err_val += err
                print('cost ', batch + 1, '/', TOTAL_BATCH_NUM_val, ':', loss, ',', err, ' (accumulated:', total_err_val, ')')

            print('Total Loss:', total_loss_val)

            total_bits = N_codewords_val * N_polar
            print('Total Errors:', total_err_val, ', total bits:', total_bits)
            print('Ex-BP BER: ', total_err_val / total_bits, '(', total_err_val, ')', sep='')
            print('Iteration Number:', polar_iter_num)
            print('Initial Alpha:', initial_alpha)
            print('Initial Beta:', initial_beta)
            print('Initial Threshold:', initial_threshold)
            print('tanh height:', tanh_height)
            print('tanh width:', tanh_width)

    stop = timeit.default_timer()
    print('Run time :', (stop - start) // 60, 'minutes,', (stop - start) % 60, 'seconds')

    winsound.Beep(freq, duration)
