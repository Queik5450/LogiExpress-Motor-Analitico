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
NOTA: Se necesita tener Prolog instalado en el dispositivo o no compilará

Ejecutar en el terminal
1.


El TMC inicial es de 45 minutos y puede cambiarse desde el menú. El programa
recarga el archivo, consulta salidas y llegadas, busca rutas por día con límite
opcional de escalas, muestra la ruta más barata o rápida y genera reportes
ordenados por costo o tiempo total.