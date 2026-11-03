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

% carga el modulo de busqueda de rutas 
:- ensure_loaded('rutas.pl').

% lee una linea del teclado
leer(Texto, Valor) :-
    write(Texto), flush_output,
    read_line_to_string(user_input, Linea),
    normalize_space(string(Valor), Linea).

% predicado principal
iniciar :-
    cargar_vuelos("vuelos.txt"),
    writeln('Vuelos cargados.'),
    menu.

menu :-
    nl,
    writeln('===== LogiExpress ====='),
    writeln('1. Salidas de una ciudad'),
    writeln('2. Llegadas a una ciudad'),
    writeln('3. Rutas validas'),
    writeln('4. Ruta mas barata'),
    writeln('5. Ruta mas rapida'),
    writeln('6. Reporte ordenado'),
    writeln('7. Cambiar TMC'),
    writeln('0. Salir'),
    leer('Opcion: ', Op),
    opcion(Op).

opcion("0") :- !, writeln('Hasta luego.').
opcion(Op) :-
    (   catch(ejecutar(Op), _, fail)
    ->  true
    ;   writeln('Opcion o dato no valido.')
    ),
    menu.

ejecutar("1") :- leer('Ciudad: ', C), salidas(C).
ejecutar("2") :- leer('Ciudad: ', C), llegadas(C).
ejecutar("3") :-
    pedir_datos(O, D, Dia),
    leer('Max escalas (Enter = sin limite): ', KS),
    escalas(KS, K),
    reporte(costo, O, D, Dia, K).
ejecutar("4") :- pedir_datos(O, D, Dia), mostrar_mejor(costo, O, D, Dia).
ejecutar("5") :- pedir_datos(O, D, Dia), mostrar_mejor(tiempo, O, D, Dia).
ejecutar("6") :-
    pedir_datos(O, D, Dia),
    leer('Ordenar por (costo/tiempo): ', CS),
    atom_string(Crit, CS),
    member(Crit, [costo, tiempo]),
    reporte(Crit, O, D, Dia, 100).
ejecutar("7") :-
    tmc(T),
    format("TMC actual: ~w min~n", [T]),
    leer('Nuevo TMC: ', S),
    number_string(N, S),
    retractall(tmc(_)),
    assertz(tmc(N)),
    format("TMC cambiado a ~w min~n", [N]).

% pide origen, destino y dia
pedir_datos(O, D, Dia) :-
    leer('Origen: ', O),
    leer('Destino: ', D),
    leer('Dia (L, M, Mi, J, V, S, D): ', Dia).

% sin numero = sin limite de escalas
escalas("", 100) :- !.
escalas(S, K) :- number_string(K, S).

% muestra la mejor ruta o avisa si no hay
mostrar_mejor(Crit, O, D, Dia) :-
    (   mejor_ruta(Crit, O, D, Dia, Ruta, Valor)
    ->  format("Mejor ruta por ~w (~w):~n", [Crit, Valor]),
        mostrar_vuelos(Ruta)
    ;   writeln('No hay rutas para ese dia.')
    ).