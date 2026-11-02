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
