# seedrandom.js version 2.3.4
# Author: David Bau
# Date: 2014 Mar 9
#
# Defines a method Math.seedrandom() that, when called, substitutes
# an explicitly seeded RC4-based algorithm for Math.random().  Also
# supports automatic seeding from local or network sources of entropy.
# Can be used as a node.js or AMD module.  Can be called with "new"
# to create a local PRNG without changing Math.random.
#
# Basic usage:
#
#   <script src=http://davidbau.com/encode/seedrandom.min.js></script>
#
#   Math.seedrandom('yay.');  // Sets Math.random to a function that is
#                             // initialized using the given explicit seed.
#
#   Math.seedrandom();        // Sets Math.random to a function that is
#                             // seeded using the current time, dom state,
#                             // and other accumulated local entropy.
#                             // The generated seed string is returned.
#
#   Math.seedrandom('yowza.', true);
#                             // Seeds using the given explicit seed mixed
#                             // together with accumulated entropy.
#
#   <script src="https://jsonlib.appspot.com/urandom?callback=Math.seedrandom">
#   </script>                 <!-- Seeds using urandom bits from a server. -->
#
#   Math.seedrandom("hello.");           // Behavior is the same everywhere:
#   document.write(Math.random());       // Always 0.9282578795792454
#   document.write(Math.random());       // Always 0.3752569768646784
#
# Math.seedrandom can be used as a constructor to return a seeded PRNG
# that is independent of Math.random:
#
#   var myrng = new Math.seedrandom('yay.');
#   var n = myrng();          // Using "new" creates a local prng without
#                             // altering Math.random.
#
# When used as a module, seedrandom is a function that returns a seeded
# PRNG instance without altering Math.random:
#
#   // With node.js (after "npm install seedrandom"):
#   var seedrandom = require('seedrandom');
#   var rng = seedrandom('hello.');
#   console.log(rng());                  // always 0.9282578795792454
#
#   // With require.js or other AMD loader:
#   require(['seedrandom'], function(seedrandom) {
#     var rng = seedrandom('hello.');
#     console.log(rng());                // always 0.9282578795792454
#   });
#
# More examples:
#
#   var seed = Math.seedrandom();        // Use prng with an automatic seed.
#   document.write(Math.random());       // Pretty much unpredictable x.
#
#   var rng = new Math.seedrandom(seed); // A new prng with the same seed.
#   document.write(rng());               // Repeat the 'unpredictable' x.
#
#   function reseed(event, count) {      // Define a custom entropy collector.
#     var t = [];
#     function w(e) {
#       t.push([e.pageX, e.pageY, +new Date]);
#       if (t.length < count) { return; }
#       document.removeEventListener(event, w);
#       Math.seedrandom(t, true);        // Mix in any previous entropy.
#     }
#     document.addEventListener(event, w);
#   }
#   reseed('mousemove', 100);            // Reseed after 100 mouse moves.
#
# The callback third arg can be used to get both the prng and the seed.
# The following returns both an autoseeded prng and the seed as an object,
# without mutating Math.random:
#
#   var obj = Math.seedrandom(null, false, function(prng, seed) {
#     return { random: prng, seed: seed };
#   });
#
# Version notes:
#
# The random number sequence is the same as version 1.0 for string seeds.
# * Version 2.0 changed the sequence for non-string seeds.
# * Version 2.1 speeds seeding and uses window.crypto to autoseed if present.
# * Version 2.2 alters non-crypto autoseeding to sweep up entropy from plugins.
# * Version 2.3 adds support for "new", module loading, and a null seed arg.
# * Version 2.3.1 adds a build environment, module packaging, and tests.
# * Version 2.3.3 fixes bugs on IE8, and switches to MIT license.
# * Version 2.3.4 fixes documentation to contain the MIT license.
#
# The standard ARC4 key scheduler cycles short keys, which means that
# seedrandom('ab') is equivalent to seedrandom('abab') and 'ababab'.
# Therefore it is a good idea to add a terminator to avoid trivial
# equivalences on short string seeds, e.g., Math.seedrandom(str + '\0').
# Starting with version 2.0, a terminator is added automatically for
# non-string seeds, so seeding with the number 111 is the same as seeding
# with '111\0'.
#
# When seedrandom() is called with zero args or a null seed, it uses a
# seed drawn from the browser crypto object if present.  If there is no
# crypto support, seedrandom() uses the current time, the native rng,
# and a walk of several DOM objects to collect a few bits of entropy.
#
# Each time the one- or two-argument forms of seedrandom are called,
# entropy from the passed seed is accumulated in a pool to help generate
# future seeds for the zero- and two-argument forms of seedrandom.
#
# On speed - This javascript implementation of Math.random() is several
# times slower than the built-in Math.random() because it is not native
# code, but that is typically fast enough.  Some details (timings on
# Chrome 25 on a 2010 vintage macbook):
#
# seeded Math.random()          - avg less than 0.0002 milliseconds per call
# seedrandom('explicit.')       - avg less than 0.2 milliseconds per call
# seedrandom('explicit.', true) - avg less than 0.2 milliseconds per call
# seedrandom() with crypto      - avg less than 0.2 milliseconds per call
#
# Autoseeding without crypto is somewhat slower, about 20-30 milliseconds on
# a 2012 windows 7 1.5ghz i5 laptop, as seen on Firefox 19, IE 10, and Opera.
# Seeded rng calls themselves are fast across these browsers, with slowest
# numbers on Opera at about 0.0005 ms per seeded Math.random().
#
# LICENSE (MIT):
#
# Copyright (c)2014 David Bau.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

###
All code is in an anonymous closure to keep the global namespace clean.
###
((global, pool, math, width, chunks, digits, module, define, rngname) ->

  #
  # The following constants are related to IEEE 754 limits.
  #

  #
  # seedrandom()
  # This is the seedrandom function described above.
  #

  # Flatten the seed string or build one from local entropy if needed.

  # Use the seed to initialize an ARC4 generator.

  # Mix the randomness into accumulated entropy.

  # Calling convention: what to return as a function of prng, seed, is_math.

  # If called as a method of Math (Math.seedrandom()), mutate Math.random
  # because that is how seedrandom.js has worked since v1.0.  Otherwise,
  # it is a newer calling convention, so return the prng directly.

  # This function returns a random double in [0, 1) that contains
  # randomness in every bit of the mantissa of the IEEE 754 value.
  # Start with a numerator n < 2 ^ 48
  #   and denominator d = 2 ^ 48.
  #   and no 'extra last byte'.
  # Fill up all significant digits by
  #   shifting numerator and
  #   denominator and generating a
  #   new least-significant-byte.
  # To avoid rounding up, before adding
  #   last byte, shift everything
  #   right using integer math until
  #   we have exactly the desired bits.
  # Form the number within [0, 1).

  #
  # ARC4
  #
  # An ARC4 implementation.  The constructor takes a key in the form of
  # an array of at most (width) integers that should be 0 <= x < (width).
  #
  # The g(count) method returns a pseudorandom integer that concatenates
  # the next (count) outputs from ARC4.  Its return value is a number x
  # that is in the range 0 <= x < (width ^ count).
  #
  ###
  @constructor
  ###
  ARC4 = (key) ->
    t = undefined
    keylen = key.length
    me = this
    i = 0
    j = me.i = me.j = 0
    s = me.S = []

    # The empty key [] is treated as [0].
    key = [keylen++]  unless keylen

    # Set up S using the standard key scheduling algorithm.
    s[i] = i++  while i < width
    i = 0
    while i < width
      s[i] = s[j = mask & (j + key[i % keylen] + (t = s[i]))]
      s[j] = t
      i++

    # The "g" method returns the next (count) outputs as one number.
    (me.g = (count) ->

      # Using instance members instead of closure state nearly doubles speed.
      t = undefined
      r = 0
      i = me.i
      j = me.j
      s = me.S
      while count--
        t = s[i = mask & (i + 1)]
        r = r * width + s[mask & ((s[i] = s[j = mask & (j + t)]) + (s[j] = t))]
      me.i = i
      me.j = j
      r

    # For robust unpredictability discard an initial batch of values.
    # See http://www.rsa.com/rsalabs/node.asp?id=2009
    ) width
    return

  #
  # flatten()
  # Converts an object tree to nested arrays of strings.
  #
  flatten = (obj, depth) ->
    result = []
    typ = (typeof obj)
    prop = undefined
    if depth and typ is "object"
      for prop of obj
        try
          result.push flatten(obj[prop], depth - 1)
    (if result.length then result else (if typ is "string" then obj else obj + "\u0000"))

  #
  # mixkey()
  # Mixes a string seed into a key that is an array of integers, and
  # returns a shortened string seed that is equivalent to the result key.
  #
  mixkey = (seed, key) ->
    stringseed = seed + ""
    smear = undefined
    j = 0
    key[mask & j] = mask & ((smear ^= key[mask & j] * 19) + stringseed.charCodeAt(j++))  while j < stringseed.length
    tostring key

  #
  # autoseed()
  # Returns an object for autoseeding, using window.crypto if available.
  #
  ###
  @param {Uint8Array|Navigator=} seed
  ###
  autoseed = (seed) ->
    try
      global.crypto.getRandomValues seed = new Uint8Array(width)
      return tostring(seed)
    catch e
      return [
        +new Date
        global
        (seed = global.navigator) and seed.plugins
        global.screen
        tostring(pool)
      ]
    return

  #
  # tostring()
  # Converts an array of charcodes to a string
  #
  tostring = (a) ->
    String.fromCharCode.apply 0, a
  startdenom = math.pow(width, chunks)
  significance = math.pow(2, digits)
  overflow = significance * 2
  mask = width - 1
  impl = math["seed" + rngname] = (seed, use_entropy, callback) ->
    key = []
    shortseed = mixkey(flatten((if use_entropy then [
      seed
      tostring(pool)
    ] else (if (not (seed?)) then autoseed() else seed)), 3), key)
    arc4 = new ARC4(key)
    mixkey tostring(arc4.S), pool
    (callback or (prng, seed, is_math_call) ->
      if is_math_call
        math[rngname] = prng
        seed
      else
        prng
    ) (->
      n = arc4.g(chunks)
      d = startdenom
      x = 0
      while n < significance
        n = (n + x) * width
        d *= width
        x = arc4.g(1)
      while n >= overflow
        n /= 2
        d /= 2
        x >>>= 1
      (n + x) / d
    ), shortseed, this is math


  #
  # When seedrandom.js is loaded, we immediately mix a few bits
  # from the built-in RNG into the entropy pool.  Because we do
  # not want to intefere with determinstic PRNG state later,
  # seedrandom will not call math.random on its own again after
  # initialization.
  #
  mixkey math[rngname](), pool

  #
  # Nodejs and AMD support: export the implemenation as a module using
  # either convention.
  #
  if module and module.exports
    module.exports = impl
  else if define and define.amd
    define ->
      impl

  return

# End anonymous scope, and pass initial values.
# global window object
# pool: entropy pool starts empty
# math: package containing random, pow, and seedrandom
# width: each RC4 output is 0 <= x < 256
# chunks: at least six RC4 outputs for each double
# digits: there are 52 significant digits in a double
# present in node.js
# present with an AMD loader
) this, [], Math, 256, 6, 52, (typeof module) is "object" and module, (typeof define) is "function" and define, "random" # rngname: name for Math.random and Math.seedrandom