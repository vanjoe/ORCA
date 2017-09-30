import argparse

# vbx_convolve_ci	1+(m+2)*(n/2)+m*(n/2)
vbx_convolve_ci = lambda n : 1 + (n+2)*(n/2) + n*(n/2)
# vbx_pool	m*n/2*2+m/2*n/2*3
vbx_pool = lambda n : n*n/2*2 + n/2*n/2*3   + n*n*2
# vbx_relu	m0*n0*2
vbx_relu = lambda n : n*n*2
# zeropad	m0*n0*2
scale_zeropad = lambda n : n*n*2
# vbx_zeropad_ci	(n0+2+2)*3 + n0*m0 + (n0+2+2)*m0
vbx_zeropad_ci = lambda n : (n+2+2)*3 + n*n + (n+2+2)*n
# copy	m0*n0
copy = lambda n : n*n
# other	n*m*2+n/2*m
other = lambda n : n*n*2 + n/2*n
# vbx_accum	3*n*m
vbx_accum = lambda n :	3*n*n


def estimate_k(l, n, k, c): 
    pool = False
    if l in [1, 3, 5]:
        pool = True

    zero = False
    if l in [1, 2, 3, 4]:
        zero = True

    ops = 0

    ops += other(n)*k
    ops += vbx_convolve_ci(n)*k*c

    xx = 1
    xx += int(c/13)
    ops += vbx_accum(n)*k*xx

    if pool:
        ops += vbx_pool(n)*k
        n = n/2
    if zero:
        ops += scale_zeropad(n)*k
        ops += vbx_zeropad_ci(n)*k
    else:
        ops += vbx_relu(n)*k
        ops += copy(n)*k

    return ops


vbx_unpack_weights = lambda i: i/32*32*3

def estimate_d(l, o, i): 
    relu = False
    if l in [0, 1]:
        relu = True
    ops = 0
    ops += o*i
    ops += o*vbx_unpack_weights(i)
    if relu:
        ops += 2*o
    ops += o

    return ops



mops = lambda ops, y: (ops / 1000000.) / y

m24 = lambda ops: mops(ops, 24)
m16 = lambda ops: mops(ops, 16)
m8 = lambda ops: mops(ops, 8)

cycles_k = [291962, 1118634, 684017, 1300487, 804936, 1213434]
expected_k = [m8(x) for x in cycles_k]
cycles_d = [373523, 84702, 11787]
expected_d = [m8(x) for x in cycles_d]


mult = lambda mo, me, c, k, n : 'x {:3.6f}'.format(8*1000000*(me/mo)/(c*k*n))
diff = lambda mo, me, c, k, n : '- {:3.6f}'.format(8*1000000*(me-mo)/(c*k*n))
compare = lambda l, c, k, n, mo, me : (l, mo, me, mult(me, mo, c, k, n), diff(me, mo, c, k, n))

compare_b = lambda l, mo, me : (l, mo, me)

adjust_k = lambda lops, c, k, n: (34*k*c*n)

adjust_d = lambda lops, p: (1800*p)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-p', '--pixels', type=int, required=True)
    parser.add_argument('-c', '--channels', type=int, required=True)
    parser.add_argument('-k', '--kernels', type=int, nargs='+', required=True)
    parser.add_argument('-d', '--dense', type=int, nargs='+', required=True)
    args = parser.parse_args()


    n = args.pixels
    p = args.pixels
    c = args.channels
    kernels = args.kernels
    dense = args.dense

    ops = 0

    expected = expected_k
    for l, k in enumerate(kernels):
        lops = estimate_k(l, n, k, c) 
        # print compare(l, c, k, n, m8(lops), expected[l])
        lops += adjust_k(lops, c, k, n)
        ops += lops

        if l in [1, 3, 5]:
            n = n/2

        c = k

    i = n*n*kernels[-1]

    expected = expected_d
    for l, d in enumerate(dense):
        lops = estimate_d(l, d, i) 
        # print compare(l, 1, 1, 1, m8(lops), expected[l])
        lops += adjust_d(lops, d)
        ops += lops

        i = d
    print(m16(ops))
