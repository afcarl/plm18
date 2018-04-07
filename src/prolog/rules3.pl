:- dynamic (*)/1.

:- op(1200, fx,     #).
:- op( 999, xfx,   (?=)).
:- op( 998, xfx,   if).
:- op( 997, xfx, then).
:- op( 996, xfy,   or).
:- op( 995, xfx,  and).
:- op( 994,  fy,  not).
:- op( 993,  fx,  (*)).
:- op( 804, xfy, (::)).
:- op( 703, xfx,   of).
:- op( 702, xfx,  now).
:- op( 100, xfx,   in).
:- op(   2,  fx, rule).
:- op(   1, xfx,  for).

%---------------------------------------------------
%  term accessors

:- F= slot/5, (dynamic F), (discontiguous F).
more(Functor = Fields0, slot(Functor,Field,Pos,Val,Term)) :- 
	Fields = [ _id | Fields0 ],
	length(Fields,N),
	functor(Term,Functor,N),
	nth1(Pos,Fields,Field),
	arg(Pos,Term,Val).

% shell to walk over slot/5
F := T :: X :- F=T :: X, T.
F  = T :: X :- with(X, F, T).

with(X :: Y, F, T) :- with(X, F, T), with(Y, F, T).
with(X =  Y, F, T) :- isa(F,T), slot(F, X, Pos,Y,_), arg(Pos, T,Y).
with(Y in X, F, T) :- with(X=Z, F, T), member(Y,Z)

isa(F,T) :- var(T) -> once(slot(F,_,_,_,T)); true.

ensure(New) :- 
  slot(F,_,_,1,Id,New),
  slot(F,_,_,1,Id,Old),
  (var(Id)      -> gensym(F, Id) ; true),
  (retract(Old) -> assert(New)   ; assert(New)).

% macro exansion hooks.
term_expansion(A =B,        Cs) :- bagof(C, more(A = B,C), Cs).
goal_expansion(F:=T :: X,    T) :- F=T :: X.
goal_expansion(F =T :: X, true) :- F=T :: X.


rule = [spec,id,task,condition,action,vars].

test(R) :-
	rule = R :: task=t.

:- listing(test).

%-------------------------------------------------
% Exanding rules with some extra details.

term_expansion( rule Id for Task if If then Then, Rule) :-
  xpandRule( rule Id for Task if If then Then, Rule).

xpandRule( rule Id for Task if If then Then, Rule) :-
  term_variables(( Id,Task,If ), V1),
  term_variables(Then, V2),
  shares(V1, V2, V),
  prims(If, Specificity),
  rule=Rule :: spec=Specificity :: id=Id 
            :: vars=V           :: task=Task 
	    :: condition=If     :: action=Then.

% returns variables shared by two lists
shares([], _, []).
shares([H | T1], L, [H | T2]) :- shares1(L, H), !, shares(T1, L, T2).
shares([_ | T1], L,      T2 ) :- shares(T1, L, T2 ).

shares1([H|_],X) :- H == X. 
shares1([_|T],X) :- shares1(T,X).

% count primitives
prims(X,N) :- prims1(X,N0), N is -1*N0.

prims1(A and B,M+N) :-  !,prims1(A,M), prims1(B,N).
prims1(A or  B,M+N) :-  !,prims1(A,M), prims1(B,N).
prims1(not A,  N)   :-    prims1(A,N).
prims1(_,1).

%-------------------------------------------------
% inference

:- dynamic done/3.
thinks(Tasks) :- 
	retractall(done(_,_,_)), 
	maplist(think, Tasks),
	listing(*).

think(Task) :-
  	setof( Rule, match(Task,Rule), Rules ), !,
  	selects(Rules, Then, Done),
  	asserta( Done ),
  	Then,
  	think(Task).
think(_).

match(Task, Spec/Rule) :-
	rule := Rule :: task = Task :: id = Id  :: spec = Spec
	             :: vars = V    :: condition = If,
        If,
        not( done( Task,Id,V ) ).

selects([ _ / Rule | _ ], Then, done(Task,Id,V) ) :-
	rule = Rule :: action=Then :: task=Task
	            :: id=Id       :: vars=V.

%-------------------------------------------------

sp(S,L)   :- flag(spyp,true) -> format(S,L) ; true.
spln(S,L) :- sp(S,L), nl.

% facts
* age of tim  =  20.
* age of john = 300.
* age of jane =   5.

term_expansion(* X,Y) :-
  X =.. [ H|T ],
  gensym(H, Id),
  Y =.. [ H,Id|T ].

% need to call order without id

grocery = [ item,type, size, frozen ].

% grocery(name,
* grocery(	bread,		bag/plastic,		medium,		n).
* grocery(	glop,		jar,			small,		n).
* grocery(	granola,	box/cardboard,		large,		n).
* grocery(	iceCream,	carton/cardboard, 	medium, 	y).
* grocery(	pepsi,		bottle,			large,		n).
* grocery(	potatoChips,	bag/plastic,		medium,		n).

rule r0
for chec_order
if   order = O items  has N and
     grocery = G with name = N with type(T)
then spyln('~w : ~w isa ~w',[I,,N,T).

%%%%%
% rules
rule b1
for check_order
if  item(potatoChips)
rule 1 
for  init
if   age of Who > 100 
then status of Who now dead. 

rule 2      
for  init 
if   Who in [tim, john] and
     age of Who > 10
then job of Who now working.


%-------------------------------------------------

X and Y      :- X, Y.
X or _       :- X.
_ or Y       :- Y.
X in Y       :- member(X,Y).
X of Y =   Z :- * X of Y = Z.
X of Y >=  Z :- * X of Y = Z0, Z0 >= Z.
X of Y =<  Z :- * X of Y = Z0, Z0 =< Z.
X of Y \=  Z :- * X of Y = Z0, Z0 \= Z.
X of Y <   Z :- * X of Y = Z0, Z0 <  Z.
X of Y >   Z :- * X of Y = Z0, Z0 >  Z.
X of Y now Z :-
  retract(* X of Y = _) -> assert(* X of Y = Z);  asserta(* X of Y = Z).

%-------------------------------------------------
%
%:- thinks, halt.
%
:- thinks( [init, elaborate, report] )..
