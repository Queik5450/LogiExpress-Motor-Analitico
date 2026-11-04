% LogiExpress - busqueda de rutas
% usa vuelo/7 y tmc/1 de main.pl

% el vuelo sale ese dia?
opera(Dias, _) :- member("Diario", Dias), !.
opera(Dias, Dia) :- member(Dia, Dias).

% hay tiempo para la conexion?
a_tiempo(inicio, _).
a_tiempo(Llegada, Salida) :-
    number(Llegada),
    tmc(T),
    Salida >= Llegada + T.

% ruta(Origen, Destino, Dia, K, Ruta)
% K = maximo de escalas, Ruta = lista de
% v(Org,Dest,Sal,Lleg,Precio,Id)
ruta(Org, Dest, Dia, K, Ruta) :-
    Max is K + 1,
    buscar(Org, Dest, Dia, inicio, [Org], Max, Ruta).

% vuelo directo al destino
buscar(Org, Dest, Dia, Hora, _, Max,
[v(Org,Dest,S,L,P,Id)]) :-
    Max >= 1,
    vuelo(Org, Dest, S, L, P, Id, Dias),
    opera(Dias, Dia),
    a_tiempo(Hora, S).

% vuelo a una escala y de ahi seguir buscando
buscar(Org, Dest, Dia, Hora, Visitadas, Max,
[v(Org,Esc,S,L,P,Id)|Resto]) :-
    Max > 1,
    vuelo(Org, Esc, S, L, P, Id, Dias),
    Esc \== Dest,
    \+ member(Esc, Visitadas),
    opera(Dias, Dia),
    a_tiempo(Hora, S),
    Max1 is Max - 1,
    buscar(Esc, Dest, Dia, L,
    [Esc|Visitadas], Max1, Resto).

    % suma de los precios de la ruta
costo([], 0).
costo([v(_,_,_,_,P,_)|Resto], C) :-
    costo(Resto, C1),
    C is C1 + P.

% llegada final menos salida inicial (incluye esperas)
tiempo(Ruta, T) :-
    Ruta = [v(_,_,Sal,_,_,_)|_],
    last(Ruta, v(_,_,_,Lleg,_,_)),
    T is Lleg - Sal.

valor(costo, Ruta, V) :- costo(Ruta, V).
valor(tiempo, Ruta, V) :- tiempo(Ruta, V).

% mergesort, Crit puede ser costo o tiempo
ordenar(_, [], []) :- !.
ordenar(_, [X], [X]) :- !.
ordenar(Crit, Lista, Ordenada) :-
    dividir(Lista, A, B),
    ordenar(Crit, A, A1),
    ordenar(Crit, B, B1),
    mezclar(Crit, A1, B1, Ordenada).

% parte la lista en dos mitades
dividir([], [], []).
dividir([X], [X], []).
dividir([X,Y|T], [X|A], [Y|B]) :- dividir(T, A, B).

% junta dos listas ya ordenadas
mezclar(_, [], L, L) :- !.
mezclar(_, L, [], L) :- !.
mezclar(Crit, [X|Xs], [Y|Ys], [X|R]) :-
    valor(Crit, X, VX),
    valor(Crit, Y, VY),
    VX =< VY, !,
    mezclar(Crit, Xs, [Y|Ys], R).
mezclar(Crit, Xs, [Y|Ys], [Y|R]) :-
    mezclar(Crit, Xs, Ys, R).

    % la mejor ruta segun costo o tiempo
mejor_ruta(Crit, Org, Dest, Dia, Ruta, Valor) :-
    findall(R, ruta(Org, Dest, Dia, 100, R), Rutas),
    ordenar(Crit, Rutas, [Ruta|_]),
    valor(Crit, Ruta, Valor).

% muestra todas las rutas ordenadas
reporte(Crit, Org, Dest, Dia, K) :-
    findall(R, ruta(Org, Dest, Dia, K, R), Rutas),
    ordenar(Crit, Rutas, Ordenadas),
    mostrar_rutas(Ordenadas, 1).

mostrar_rutas([], 1) :- !, writeln('No hay rutas para ese dia.').
mostrar_rutas([], _).
mostrar_rutas([R|Resto], N) :-
    costo(R, C),
    tiempo(R, T),
    format("Ruta ~w: costo ~w, tiempo ~w min~n", [N, C, T]),
    mostrar_vuelos(R),
    N1 is N + 1,
    mostrar_rutas(Resto, N1).

mostrar_vuelos([]).
mostrar_vuelos([v(O,D,S,L,_,Id)|Resto]) :-
    min_a_hora(S, HS),
    min_a_hora(L, HL),
    format("   ~w: ~w ~w -> ~w ~w~n", [Id, O, HS, D, HL]),
    mostrar_vuelos(Resto).

% 450 -> 07:30
min_a_hora(Min, Hora) :-
    H is Min // 60,
    M is Min mod 60,
    dos_digitos(H, HH),
    dos_digitos(M, MM),
    atomic_list_concat([HH, ':', MM], Hora).

dos_digitos(N, S) :- N < 10, !,
    format(atom(S), "0~d", [N]).
dos_digitos(N, S) :-
    number_string(N, S).
