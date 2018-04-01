
[home](http://tiny.cc/plm18) |
[copyright](https://github.com/txt/plm18/blob/master/LICENSE.md) &copy;2018, tim&commat;menzies.us
<br>
[<img width=900 src="https://raw.githubusercontent.com/txt/plm18/master/img/banner.png">](http://tiny.cc/plm18)<br>
[syllabus](https://github.com/txt/plm18/blob/master/doc/syllabus.md) |
[src](https://github.com/txt/plm18/tree/master/src) |
[submit](http://tiny.cc/plm18give) |
[chat](https://plm18.slack.com/)


______




# Macros

These notes are adapted from `http://aplcenmp.apl.jhu.edu/~hall/'.

   For more notes on macros, see Graham p162 to 172.

## What is a Macro and Why Should I Care?

A macro is a program called at runtime to write other programs.

They are used to expand shorthand into longhand.

- Macros in LISP are particularly nice. LISP manipluates lists. LISP
  programs are lists. LISP macros rewrite lists to add in the required
  details.


Note that there is much more to writing macros than shown below. For
more details, see http://www.gigamonkeys.com/book/macros-defining-your-own.html

Note also that for decades, LISP was the king of macros. Now, finally,
other languages have caught on. So JULIA has a macro system that is
(nearly) as powerful as LISP. So macros live!

## Macros in Julia

What is Julia? Think "next generation Python". 
[Fast as heck](https://julialang.org/#high-performance-jit-compiler). 
Scales.  A language to watch.

From [Julua](https://julialang.org/):

- Julia is a high-level, high-performance dynamic programming
  language for numerical computing. It provides a sophisticated
  compiler, distributed parallel execution, numerical accuracy, and
  an extensive mathematical function library. Julia’s Base library,
  largely written in Julia itself, also integrates mature, best-of-breed
  open source C and Fortran libraries for linear algebra, random
  number generation, signal processing, and string processing.

But that does not matter now.
Julia has a type system, with some limits. E.g. default
Julia does not let you define types with default variables.

So here's a macro that genertes a `type` and `function $(name)`.

    #------------------------------------------------
    # define types and a constructor that drops in the
    # right default values
    # e.g. @def emp age=0 salary=10000
    macro has(typename, pairs...)
        name = esc(symbol(string(typename,0)))
        x    = esc(symbol("x"))
        ones = [  x.args[1]  for x in pairs ]
        twos = [  x.args[2]  for x in pairs ]
        sets = [ :($x.$y=$y) for y in ones  ]
        :(type $(typename)
             $(ones...)
          end;
          function $(name)(; $(pairs...) )
            $x = $(typename)($(twos...))
            $(sets...)
            $x
          end)
    end

Example

    @has aa bb=1 cc=10+1

First, we get the results of the macro

     begin
        type aa # /Users/timm/gits/timm/15/jl/one.jl, line 18:
            bb
            cc
        end
        function aa0() # /Users/timm/gits/timm/15/jl/one.jl, line 21:
            aa(1,10 + 1)
        end
     end

Secondly, lets call some functions.  Julia programs are organized
around multiple dispatch, which allows built-in and user-defined
functions to be overloaded for different combinations of argument
types.

    someFun(x::Any) = println(1000000)
    someFun(x::aa)  = println(x.bb)

So if this code rules, we can use `aa0`  to build a type that
auto-assigns some fields to something of type `aa`, and
initialize its fields to `1` and `10+1`.

    x    = aa0()
    x.bb = 200

    someFun(22)
    someFun(x)

Running results:

    1000000
    200
    
## Lisp Macros for Object Orientation

### OO Version1 (no macros, yet)

Here's some code we've seen before for objects-as-lambdas.
It works ok but, really, the objects it creates are very verbose.

    (defun point (&key (x 0) (y 0))
      (labels (
         (x?   ()  x)
         (y?   ()  y)
         (x!   (z) (setf x z))
         (y!   (z) (setf y z))
         (_sq  (z) (* z z))
         (dist (x2 y2)
           (let ((x1 (x?))
                 (y1 (y?)))
             (sqrt (+ (_sq (- x1 x2)) 
                      (_sq (- y1 y2)))))))
        (lambda (z &rest args)
          (case z
            (x? (x?))
            (y? (y?))
            (x! (x! (first args)))
            (y! (y! (first args)))
            (dist (dist (first args) (second args)))
            (otherwise 
              (error "~a unknown" z))))))
    
    (defun say0 (self m &rest args) (print (apply self (cons m args))))
    (defun ask0 (self m &rest args)        (apply self (cons m args)))
    
    (let ((self (point :x 1 :y 1)))
      (format t "~%~%;--------- point ------------~%")
      (say0 self 'x?)
      (ask0 self 'x! 2)
      (say0 self 'x?)
      (say0 self 'dist 10 10)
      (print self))
    
### OO Version2 (still no macros, yet)

Here's a version where instances are just a pointer
to a lambda body and a list of instance variables. Much
better when dealing with 1000s to 1000000s of instances.

In the following, `self` is the instance.

    (defun make (klass  &rest args) 
       (cons klass args))

    (defun say (self m &rest args) 
       (print (funcall (car self) self m args)))

    (defun ask (self m &rest args)        
       (funcall (car self) self m args))
    
    (defun point2 ()
      (labels (
         (_sq  (z)      (* z z))
         (dist (self x2 y2)
           (let ((x1 (ask self 'x?))
                 (y1 (ask self 'y?)))
             (sqrt (+ (_sq (- x1 x2)) 
                      (_sq (- y1 y2)))))))
        (lambda (self z args)
          (case z
            (x?         (nth 0 (cdr self)))
            (y?         (nth 1 (cdr self)))
            (x!   (setf (nth 0 (cdr self)) (nth 0 args)))
            (y!   (setf (nth 1 (cdr self)) (nth 1 args)))
            (dist (dist self (first args) (second args)))
            (otherwise 
              (error "~a unknown" z))))))
    
    (let* ((klass (point2))
           (self  (make klass 1 1)))
      (format t "~%~%;--------- point2 ------------~%")
      (say self 'x?)
      (ask self 'x! 2)
      (say self 'x?)
      (say self 'dist 10 10)
      (print (cdr self)))
    
### OO Version3 (macros! succinctness!)

Note that the above klasses have template that look like this:

    (defmacro defklass (klass lst &rest body)
      "template for klasses"
      `(defun ,klass ()
         (labels (,@body)
           (lambda (self %z args)
             (case %z
               ,@(getsets lst)
               ,@(method-calls-with-n-args body)
               (otherwise 
                 (error "~a unknown" %z)))))))

As to the magic `getsets` function, this creates a setter and
a getter for each variables (e.g. see the definitions of `x?` and `x!`
above).

    (defun getsets (lst)
      "for each instance x variable in lst,
       build a getter, setter for x? and x!"
      (let ((n -1) out)
        (labels (
          (sym (x y) (intern (string-upcase (format nil "~a~a" x y))))
          (getter (x)
                  (let ((get (sym x "?"))
                        (set (sym x "!")))
                    `((,get       (nth ,(incf n) (cdr self)))
                      (,set (setf (nth ,n (cdr self)) (car args)))))))
          (dolist (x lst out)
            (dolist (y (getter x))
              (push y out))))))

As to the magic `method-calls-with-n-args` function,
this looks up methods and their number of arguments,
and adds in the right entry to the case statement (e.g. see
the definition of `dist`, above).

    (defun method-calls-with-n-args (sexps &aux out)
      "work out #args each method,
       return one item for the dispatch case
       statement for each method"
      (labels (
         (arg1 (m n) 
               (when (< m n)
                 (cons  `(nth ,m args) (arg1 (1+ m) n)))))
        (dolist (sexp sexps out)
          (let* ((f    (first sexp))
                (n     (length (second sexp)))
                (args  (arg1 0 (1- n)))
                (call `(,f (,f self ,@args))))
            (unless (eq #\_ (char (string f) 0))
              (push call  out))))))
    
Now we can spec a klass, oh so succinctly

    (defklass point3 (x y)
       (_sq  (z) (* z z))
       (dist (self x2 y2)
             (let ((x1 (ask self 'x?))
                   (y1 (ask self 'y?)))
               (sqrt (+ (_sq (- x1 x2)) 
                        (_sq (- y1 y2)))))))
    
This expans exactly to what we want.

    (macroexpand-1 '(defobject point3 (x y)
       (_sq  (z) (* z z))
       (dist (self x2 y2)
             (let ((x1 (ask self 'x?))
                   (y1 (ask self 'y?)))
               (sqrt (+ (_sq (- x1 x2)) 
                        (_sq (- y1 y2))))))))
    
    (DEFUN POINT3 NIL
     (LABELS
      ((_SQ (Z) (* Z Z))
       (DIST (SELF X2 Y2)
        (LET ((X1 (ASK SELF 'X?)) 
              (Y1 (ASK SELF 'Y?)))
         (SQRT (+ (_SQ (- X1 X2)) (_SQ (- Y1 Y2)))))))
      (LAMBDA (SELF %Z ARGS)
       (CASE %Z 
             (Y!   (SETF (NTH 1 (CDR SELF)) (CAR ARGS))) 
             (Y?         (NTH 1 (CDR SELF)))
             (X!   (SETF (NTH 0 (CDR SELF)) (CAR ARGS))) 
             (X?         (NTH 0 (CDR SELF)))
             (DIST (DIST SELF (NTH 0 ARGS) (NTH 1 ARGS)))
             (OTHERWISE (ERROR "~a unknown" %Z))))))
    
And it all works fine

    (let* ((klass (point3))
           (self  (make klass 1 1)))
      (format t "~%~%;--------- point3 ------------~%")
      (say self 'x?)
      (ask self 'x! 2)
      (say self 'x?)
      (say self 'dist 10 10)
      (print (cdr self)))

## Under the hood

### LISP TICK vs BACK TICKS

Back ticks create a toggle mode within which things are not evaluated
unless they are proceeded by a comma.

   This allows for the simple definition of nested list structures.
For example, the following tells LISP to convert all calls to

    (time-it 10 (run-this-long-function))

with code that runs some slow function ten times, then returns the
mean time times across those ten calls.

    (defmacro time-it (n &body body)
      "Run 'body' 'n' times."
      (let ((n1 (gensym))
            (i  (gensym))
            (t1 (gensym)))
        `(let ((,n1 ,n)
               (,t1 (get-internal-run-time)))
           (dotimes (,i ,n1) ,@body)
           (float (/ (- (get-internal-run-time) ,t1)
                     (* ,n1 internal-time-units-per-second))))))

Pretty neat, heh? Less typing for you, more auto-generated code.

To explain the above, we need to know about _macros_

### What are Macros ?

Macros in Lisp provide a very powerful and flexible method of extending
Lisp syntax.

Macros are programs to write programs. They are called when a
program is first loaded from file into LISP. They expand succinct
expressions into longer, executable, forms.  Since the expansion
happens only once at load time, they have zero runtime cost after that.

Lisp functions take Lisp values as input and return Lisp values.
They are executed at run-time.

Lisp macros take Lisp code as input, and return Lisp code. They are
executed at compiler pre-processor time, just like in C. The resultant
code gets executed at run-time.

### Basic Idea

Macros take unevaluated Lisp code and return a Lisp form. This form
should be code that calculates the proper value. Example:

    (defmacro Square-1 (X)
        `(* ,X ,X))
    
That is, wherever LISP reads  	`(Square-1 XXX)`, 
it replaces it with `(* XXX XXX)`.

The resultant code is what the compiler sees.

### Traps For Beginners

1. Trying to evaluate arguments at compile time
2. Evaluating arguments too many times
3. Variable name clashes.

#### Compile Time Eval Error

Macros are expanded at compiler pre-processor time. So this is an error:

    (defmacro Square-2 (X)
        (* X X))

This would indeed work for `(Square-2 4)`, but would crash for
`(Square-2 X)`, since `X` is probably a variable whose value is not known
until run-time.

### Evaluating arguments too many times

    (defmacro Square-1 (X) `(* ,X ,X))

This looks OK on first blush. However, try macroexpand-1'ing a form,
and you notice that it evaluates its arguments twice:

    (macroexpand-1 '(Square-1 (Foo 2)))
    ==> (* (Foo 2) (Foo 2))

`Foo` gets called _twice_, but it should only be called once.
Inefficient.

Also, returns the wrong value if Foo does not always return the same
value.

    (Square-1 (incf X))
    (Square-1 (random 10))

So, to fix this, we eval the argument once, cache the result, and
use it many times.

    (defmacro Square-3 (X)
        `(let ((Temp ,X))
    	   (* Temp Temp)))

How does that look?

    (macroexpand-1 '(Square-3 (Foo 2)))
    ==> (let ((Temp (Foo 2)))
    	           (* Temp Temp))

Which is nearly what we want.... except for variable name clashes.

### Variable name clashes

Square-3 is perfectly safe, but consider instead the following macro,
which takes two numbers and squares the sum of them:

    (defmacro Square-Sum-1 (X Y)
        `(let* ((First ,X)
                (Second ,Y)
    		    (Sum (+ First Second)))
    	    (* Sum Sum)) )

This looks pretty good, even after macroexpansion:

    (macroexpand-1 '(Square-Sum-1 3 4))
    
    ==> (LET* ((FIRST 3)
               (SECOND 4)
               (SUM (+ FIRST SECOND)))
          (* SUM SUM))

which seems ok. BUT the local variables we chose would conflict with
existing local variable names if a variable named First already
existed.  E.g.

    (macroexpand-1 '(Square-Sum-1 1 First))
    ==> (LET* ((FIRST 1)
               (SECOND FIRST)
               (SUM (+ FIRST SECOND)))
          (* SUM SUM))

 The problem here is that `(SECOND FIRST)` gets the value of the new
local variable `FIRST`, not the one you passed in. Thus

     (let ((First 9)) (Square-Sum-1 1 First))

 returns 4, not 100!

Solution: need to create a variable name inside the macro that
cannot exist anywhere else in the code.

    (defmacro Square-Sum (X Y)
        (let ((First (gensym "FIRST-"))
              (Second (gensym "SECOND-"))
              (Sum (gensym "SUM-")))
          '(let* ((,First ,X)
                  (,Second ,Y)
                  (,Sum (+ ,First ,Second)))
               (* ,Sum ,Sum))
    	  ))

Now

    (macroexpand-1 '(Square-Sum 1 First))
    ==> (LET* ((#:FIRST-590 1)
               (#:SECOND-591 FIRST)
               (#:SUM-592 (+ #:FIRST-590 #:SECOND-591)))
           (* #:SUM-592 #:SUM-592))

This expansion has no dependence on any local variable names in the
macro definition itself, and since the generated ones are guaranteed to
be unique, is safe from name collisions.

Just to complete the picture, there is the "real" definition of
square:

    (defmacro square (x)
      	(let ((temp (gensym)))
    	  `(let ((,temp ,x))
    
## Other Examples

### While

    (defmacro while (test &body body)
      "implements 'while' (which is not standard in LISP)"
      `(do ()
           ((not ,test))
         ,@body))

Expansion:

    (macroexpand-1 '(while (> (decf n) 0) 
                      (print n)))
    
    (DO NIL 
        ((NOT (> (DECF N) 0))) 
           (PRINT N))

### Until (defined using While)

    (defmacro until (test &body body)
      "implements 'until' (which is not standard in LISP)"
      `(while (not ,test)
         ,@body))
    
Expansion:
    (macroexpand-1 '(until (> (decf n) 0) 
                      (print n)))
    
    (WHILE (NOT (> (DECF N) 0)) 
           (PRINT N)) 


### Nested Slot Access

Example of a recurisve macros. Very slick.

Fixes a problem in LISP, not chains of "`.`" to handle nested
object attributes:

    (defmacro ? (obj first-slot &rest more-slots)
      "From https://goo.gl/dqnmvH:"
      (if (null more-slots)
          `(slot-value ,obj ',first-slot)
          `(? (slot-value ,obj ',first-slot) ,@more-slots)))
    
Expansion

    (macroexpand '(? obj a b c d))
    
    (SLOT-VALUE 
      (SLOT-VALUE 
        (SLOT-VALUE 
          (SLOT-VALUE OBJ 'A) 
          'B) 
        'C) 
      'D)

### Looping

Loop 0..9, return n:

    (macroexpand '(dotimes (i 10 n) (Incf n i)))
    
    (BLOCK NIL
      (LET ((I 0))
        (DECLARE (TYPE UNSIGNED-BYTE I))
        (TAGBODY
          (GO #:G620)
         #:G619
          (TAGBODY (INCF N I))
          (PSETQ I (1+ I))
         #:G620
          (UNLESS (>= I 10) (GO #:G619))
          (RETURN-FROM NIL (PROGN N)))))

Aren't you glad that you've never seen this before and you'll never
have to see it again?

### Anaphoric Macros


This one is really famous. Can you guess what it does?

    (defmacro aif (test then &optional else)
      `(let ((it ,test))
         (if it ,then ,else)))

From Graham's _On LISP_ book:

In natural language, an anaphor is an expression which refers back
in the conversation. The most common anaphor in English is probably
"it," as in "Get the wrench and put it on the table." Anaphora are a
great convenience in everyday language-imagine trying to get along
without them-but they don't appear much in programming languages. For
the most part, this is good. Anaphoric expressions are often genuinely
ambiguous, and present-day programming languages are not designed to
handle ambiguity.

However, it is possible to introduce a very limited form of anaphora
into Lisp programs without causing ambiguity. An anaphor, it turns out,
is a lot like a captured symbol. We can use anaphora in programs by
designating certain symbols to serve as pronouns, and then writing
macros intentionally to capture these symbols.

Example use:

    (aif (big-long-calculation)
         (foo it))
    
When you use an aif, the symbol _it_ is bound to the result returned
by the test clause. This can be reused without repeating some long
expensive test.

### Timing Execution

Now we can explain the _time-it_ code that started this lecture.

    (defmacro time-it (n &body body)
      "Run 'body' 'n' times."
      (let ((n1 (gensym))
            (i  (gensym))
            (t1 (gensym)))
        `(let ((,n1 ,n)
               (,t1 (get-internal-run-time)))
           (dotimes (,i ,n1) ,@body)
           (float (/ (- (get-internal-run-time) ,t1)
                     (* ,n1 internal-time-units-per-second))))))
    
Compile-time evaluation is avoided by returning a  list that defines
a let environment inside of which we can run or code.

Extra evaluations are avoided by computing _n_ once and caching that
result in _n1_.

And the gensyms avoid variable name clashes.

## Warning

Beginners have a lot of trouble with macros. They can get fiendishly
difficult.  But every experienced LISP programmer uses them. So use
them carefully at first and soon you will be LISP programming guru
writing macros to write macros.

For the absolute best book on macros in LISP, see the amazing Let
Over Lambda (http://letoverlambda.com/) book by Doug Hoyte.  Absolutely
not for beginners.

