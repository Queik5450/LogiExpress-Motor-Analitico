% Proyecto LogiExpress - parte de Prolog

:- dynamic vuelo/7.
:- dynamic tmc/1.

% tiempo minimo de conexion (min)
tmc(45).

% pasa la hora "HH:MM" a minutos
hora_a_min(Hora, Min) :-
    split_string(Hora, ":", " ", [H, M]),
    number_string(H1, H),
    number_string(M1, M),
    Min is H1*60 + M1.

% carga los vuelos del archivo
cargar_vuelos(Archivo) :-
    retractall(vuelo(_,_,_,_,_,_,_)),
    read_file_to_string(Archivo, Texto, []),
    split_string(Texto, "\n", "\r ", Lineas),
    forall((member(L, Lineas), L \== ""), guardar_vuelo(L)).

% vuelo(origen, destino, salida, llegada, precio, id, dias)
guardar_vuelo(Linea) :-
    split_string(Linea, "|", " ", [Org, Dest, HSal, HLleg, Pre, Id, D]),
    hora_a_min(HSal, Sal),
    hora_a_min(HLleg, Lleg),
    number_string(Precio, Pre),
    split_string(D, "-", " ", Dias),
    assertz(vuelo(Org, Dest, Sal, Lleg, Precio, Id, Dias)).

% pasa minutos a "HH:MM" para mostrar
hora_texto(Min, Texto) :-
    H is Min // 60,
    M is Min mod 60,
    format(atom(Texto), "~|~`0t~d~2+:~|~`0t~d~2+", [H, M]).

% imprime un vuelo en una linea
mostrar_vuelo(Id, Org, Dest, Sal, Lleg, Precio) :-
    hora_texto(Sal, HS),
    hora_texto(Lleg, HL),
    format("  ~w  ~w ~w -> ~w ~w  (~w Bs)~n", [Id, Org, HS, Dest, HL, Precio]).

% vuelos que salen de una ciudad
salidas(Ciudad) :-
    \+ vuelo(Ciudad, _, _, _, _, _, _), !,
    format("No hay vuelos que salgan de ~w~n", [Ciudad]).
salidas(Ciudad) :-
    format("Salidas desde ~w:~n", [Ciudad]),
    forall(vuelo(Ciudad, D, S, L, P, Id, _),
           mostrar_vuelo(Id, Ciudad, D, S, L, P)).

% vuelos que llegan a una ciudad
llegadas(Ciudad) :-
    \+ vuelo(_, Ciudad, _, _, _, _, _), !,
    format("No hay vuelos que lleguen a ~w~n", [Ciudad]).
llegadas(Ciudad) :-
    format("Llegadas a ~w:~n", [Ciudad]),
    forall(vuelo(O, Ciudad, S, L, P, Id, _),
           mostrar_vuelo(Id, O, Ciudad, S, L, P)).