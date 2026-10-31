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