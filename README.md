# LogiExpress - Haskell y Prolog

Formato de cada línea de `vuelos.txt`:

Origen|Destino|HH:MM|HH:MM|precio|identificador|Diario


Compilar y ejecutar:

A - Programa de Haskell:
NOTA: Se necesita tener Haskell instalado en el dispositivo o no compilará

Ejecutar en el terminal
1. ghc haskell/main.hs -o logiexpress
2. .\logiexpress.exe


B - Programa de Prolog:
NOTA: Se necesita tener SWI-Prolog instalado en el dispositivo o no se podrá ejecutar

Ejecutar en el terminal desde la carpeta principal del proyecto
1. swipl prolog/main.pl
2. iniciar.

Opciones del menú de Prolog:
1. Salidas de una ciudad
2. Llegadas a una ciudad
3. Rutas válidas (con límite opcional de escalas)
4. Ruta más barata
5. Ruta más rápida
6. Reporte ordenado por costo o por tiempo
7. Cambiar el TMC
0. Salir

Las ciudades se escriben igual que en vuelos.txt (ej. Pto Ordaz) y los días como L, M, Mi, J, V, S o D.


El TMC inicial es de 45 minutos y puede cambiarse desde el menú. El programa
recarga el archivo, consulta salidas y llegadas, busca rutas por día con límite
opcional de escalas, muestra la ruta más barata o rápida y genera reportes
ordenados por costo o tiempo total.