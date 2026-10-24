module Main where

import Control.Exception (IOException, try)
import Data.Char (toLower)
import Data.List (intercalate, sortOn)
import System.IO (hFlush, stdout)
import Text.Read (readMaybe)

type Minutos = Int
type Grafo = [Vuelo]

data Vuelo = Vuelo
  { origen :: String, destino :: String, salida :: Minutos, llegada :: Minutos
  , precio :: Double, identificador :: String, dias :: [String]
  } deriving (Eq, Show)

newtype Ruta = Ruta { vuelos :: [Vuelo] } deriving (Eq, Show)

tmc :: Minutos
tmc = 45

horaAMinutos :: String -> Either String Minutos
horaAMinutos texto =
  case break (== ':') (trim texto) of
    (h, ':' : m) ->
      case (readMaybe h, readMaybe m) of
        (Just hora, Just minuto)
          | hora >= 0 && hora < 24 && minuto >= 0 && minuto < 60 ->
              Right (hora * 60 + minuto)
        _ -> Left ("Hora invalida: " ++ texto)
    _ -> Left ("Hora invalida: " ++ texto)

minutosAHora :: Minutos -> String
minutosAHora n = dos (n `div` 60 `mod` 24) ++ ":" ++ dos (n `mod` 60)
  where dos x = if x < 10 then '0' : show x else show x

normalizar :: String -> String
normalizar = map toLower . unwords . words

diaNormalizado :: String -> String
diaNormalizado dia = case normalizar dia of
  "lunes" -> "l"; "martes" -> "m"; "miercoles" -> "mi"; "miércoles" -> "mi"
  "jueves" -> "j"; "viernes" -> "v"; "sabado" -> "s"; "sábado" -> "s"
  "domingo" -> "d"; x -> x

splitOn :: Char -> String -> [String]
splitOn separador = foldr acumular [""]
  where
    acumular c (x:xs)
      | c == separador = "" : x : xs
      | otherwise = (c : x) : xs
    acumular _ [] = []

trim :: String -> String
trim = unwords . words

operaEl :: String -> Vuelo -> Bool
operaEl dia vuelo =
  let frecuencia = concatMap (splitOn '-') (dias vuelo)
      disponibles = map diaNormalizado frecuencia
  in any ((== "diario") . normalizar) (dias vuelo)
      || diaNormalizado dia `elem` disponibles

parsearVuelo :: String -> Either String Vuelo
parsearVuelo linea =
  case map trim (splitOn '|' linea) of
    [o, d, hs, hl, coste, codigo, frecuencia] -> construir o d hs hl coste codigo frecuencia
    [ruta, hs, hl, coste, codigo, frecuencia] ->
      case separarRuta ruta of
        Just (o, d) -> construir o d hs hl coste codigo frecuencia
        Nothing -> Left ("Ruta invalida: " ++ ruta)
    _ -> Left ("Linea invalida: " ++ linea)
  where
    construir o d hs hl coste codigo frecuencia = do
      s <- horaAMinutos hs
      l <- horaAMinutos hl
      p <- maybe (Left ("Precio invalido: " ++ coste)) Right (readMaybe coste)
      if null o || null d || null codigo || p < 0
        then Left "Origen, destino, identificador y precio deben ser validos"
        else if l < s then Left "La llegada no puede ser anterior a la salida"
        else Right (Vuelo o d s l p codigo [frecuencia])

separarRuta :: String -> Maybe (String, String)
separarRuta texto =
  firstJust [partir separador | separador <- ["->", ">", ","]]
  where
    partir separador =
      case breakString separador texto of
        Just (a, b) | not (null (trim a)) && not (null (trim b)) ->
          Just (trim a, trim b)
        _ -> Nothing
    firstJust [] = Nothing
    firstJust (x:xs) = case x of Just _ -> x; Nothing -> firstJust xs

breakString :: String -> String -> Maybe (String, String)
breakString separador texto = buscar "" texto
  where
    buscar _ [] = Nothing
    buscar antes resto
      | separador `prefixo` resto = Just (antes, drop (length separador) resto)
      | otherwise = buscar (antes ++ [head resto]) (tail resto)
    prefixo [] _ = True
    prefixo _ [] = False
    prefixo (x:xs) (y:ys) = x == y && prefixo xs ys

cargarVuelos :: FilePath -> IO (Either String Grafo)
cargarVuelos archivo = do
  resultado <- try (readFile archivo) :: IO (Either IOException String)
  pure $ case resultado of
    Left e -> Left (show e)
    Right contenido ->
      let lineas = filter (not . null . trim) (lines contenido)
          parseados = map parsearVuelo lineas
          errores = [e | Left e <- parseados]
      in if null errores then Right [v | Right v <- parseados]
        else Left (head errores)

salidasDe :: String -> Grafo -> Grafo
salidasDe ciudad = filter ((== normalizar ciudad) . normalizar . origen)

llegadasA :: String -> Grafo -> Grafo
llegadasA ciudad = filter ((== normalizar ciudad) . normalizar . destino)

rutas :: String -> String -> String -> Maybe Int -> Grafo -> [Ruta]
rutas = rutasConTMC tmc

rutasConTMC :: Minutos -> String -> String -> String -> Maybe Int -> Grafo -> [Ruta]
rutasConTMC minimo inicio fin dia limite grafo = buscar (normalizar inicio) [] [normalizar inicio]
  where
    objetivo = normalizar fin
    buscar ciudad camino visitadas
      | ciudad == objetivo = [Ruta (reverse camino)]
      | maybe False (\k -> length camino - 1 >= k) limite = []
      | otherwise =
          [ ruta
          | vuelo <- grafo
          , normalizar (origen vuelo) == ciudad
          , operaEl dia vuelo
          , normalizar (destino vuelo) `notElem` visitadas
          , compatible camino vuelo
          , ruta <- buscar (normalizar (destino vuelo)) (vuelo : camino)
              (normalizar (destino vuelo) : visitadas)
          ]
    compatible [] _ = True
    compatible (anterior:_) actual = salida actual >= llegada anterior + minimo

escalas :: Ruta -> Int
escalas (Ruta xs) = max 0 (length xs - 1)

costoRuta :: Ruta -> Double
costoRuta (Ruta xs) = sum (map precio xs)

tiempoRuta :: Ruta -> Minutos
tiempoRuta (Ruta []) = 0
tiempoRuta (Ruta xs) = llegada (last xs) - salida (head xs)

optimizarCosto :: String -> String -> String -> Grafo -> [Ruta]
optimizarCosto a b d = take 1 . sortOn costoRuta . rutas a b d Nothing

optimizarTiempo :: String -> String -> String -> Grafo -> [Ruta]
optimizarTiempo a b d = take 1 . sortOn tiempoRuta . rutas a b d Nothing

mostrarRuta :: Ruta -> String
mostrarRuta (Ruta []) = "Sin vuelos"
mostrarRuta ruta@(Ruta xs) =
  origen (head xs) ++ " -> " ++ destino (last xs) ++
  " | vuelos: " ++ intercalate ", " (map identificador xs) ++
  " | escalas: " ++ show (escalas ruta) ++
  " | costo: " ++ show (costoRuta ruta) ++
  " | tiempo: " ++ show (tiempoRuta ruta) ++ " min"

mostrarVuelo :: Vuelo -> String
mostrarVuelo v = identificador v ++ ": " ++ origen v ++ " -> " ++ destino v ++
  " (" ++ minutosAHora (salida v) ++ "-" ++ minutosAHora (llegada v) ++
  ", " ++ show (precio v) ++ ")"

mostrarVuelos :: Grafo -> String
mostrarVuelos = unlines . map mostrarVuelo

menu :: FilePath -> Minutos -> Grafo -> IO ()
menu archivo minimo grafo = do
  putStrLn "\n1) Cargar/recargar  2) Configurar TMC  3) Salidas  4) Llegadas"
  putStrLn "5) Rutas  6) Menor costo  7) Menor tiempo  8) Reporte  9) Salir"
  opcion <- pedir "Opcion: "
  case opcion of
    "1" -> cargarVuelos archivo >>= informarCarga
    "2" -> configurarTMC minimo
    "3" -> consultaVuelos salidasDe
    "4" -> consultaVuelos llegadasA
    "5" -> consultarRutas id
    "6" -> consultarRutas (sortOn costoRuta)
    "7" -> consultarRutas (sortOn tiempoRuta)
    "8" -> reporte
    "9" -> pure ()
    _ -> putStrLn "Opcion invalida." >> menu archivo minimo grafo
  where
    continuar nuevoTMC nuevoGrafo = menu archivo nuevoTMC nuevoGrafo
    informarCarga resultado = case resultado of
      Left e -> putStrLn ("Error: " ++ e) >> continuar minimo grafo
      Right nuevo -> putStrLn ("Vuelos cargados: " ++ show (length nuevo)) >>
        continuar minimo nuevo
    configurarTMC actual = do
      valor <- pedir "Nuevo TMC en minutos: "
      case readMaybe valor of
        Just n | n >= 0 -> continuar n grafo
        _ -> putStrLn "TMC invalido." >> continuar actual grafo
    consultaVuelos consulta = do
      ciudad <- pedir "Ciudad: "
      putStr (mostrarVuelos (consulta ciudad grafo))
      continuar minimo grafo
    consultarRutas ordenar = do
      a <- pedir "Origen: "
      b <- pedir "Destino: "
      d <- pedir "Dia: "
      kTexto <- pedir "Maximo de escalas (vacio = sin limite): "
      let limite = if null kTexto then Nothing else readMaybe kTexto
          encontrados = ordenar (rutasConTMC minimo a b d limite grafo)
      if null encontrados then putStrLn "No se encontraron rutas."
      else putStr (unlines (map mostrarRuta encontrados))
      continuar minimo grafo
    reporte = do
      a <- pedir "Origen: "; b <- pedir "Destino: "; d <- pedir "Dia: "
      criterio <- pedir "Orden (costo/tiempo): "
      let ordenar = if normalizar criterio == "tiempo" then sortOn tiempoRuta else sortOn costoRuta
      putStr (unlines (map mostrarRuta (ordenar (rutasConTMC minimo a b d Nothing grafo))))
      continuar minimo grafo

pedir :: String -> IO String
pedir texto = putStr texto >> hFlush stdout >> getLine

main :: IO ()
main = do
  cargado <- cargarVuelos "vuelos.txt"
  case cargado of
    Left e -> putStrLn ("Error: " ++ e)
    Right grafo -> putStrLn ("Vuelos cargados: " ++ show (length grafo)) >>
      menu "vuelos.txt" tmc grafo
