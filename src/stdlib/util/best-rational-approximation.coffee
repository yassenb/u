# inspired from http://shreevatsa.wordpress.com/2011/01/10/not-all-best-rational-approximations-are-the-convergents-of-the-continued-fraction/

@approximate = (x, n) ->
  p0 = 0; q0 = 1
  p1 = 1; q1 = 0
  a = null
  num = x
  i = Math.floor x
  loop
    a = Math.floor num
    p2 = a * p1 + p0
    q2 = a * q1 + q0
    num = 1 / (num - a)

    break if q2 > n

    p0 = p1; p1 = p2
    q0 = q1; q1 = q2

    return [i, p1 - i * q1, q1] if num is Infinity

  # At this point p1 and q1 hold the nominator and denominator of the best rational approximation as a convergent of a
  # continued fraction. However, not all best rational approximations are of the aforementioned type
  a = Math.ceil(a / 2)
  ++a if Math.abs(x - (a * p1 + p0) / (a * q1 + q0)) >= Math.abs(x - p1 / q1)

  q = q1
  while (newQ = a * q1 + q0) <= n
    q = newQ
    ++a
  --a
  p = if q is q1 then p1 else a * p1 + p0

  [i, p - i * q, q]
