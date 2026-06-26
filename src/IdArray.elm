module IdArray exposing (IdArray, empty, foldl, foldr, fromList, get, initialize, length, set, toList)

import Array exposing (Array)
import Id exposing (Id)


type IdArray k v
    = IdArray (Array v)


get : Id k -> IdArray k v -> Maybe v
get key (IdArray array) =
    Array.get (Id.toInt key) array


set : Id k -> v -> IdArray k v -> IdArray k v
set key value (IdArray array) =
    Array.set (Id.toInt key) value array |> IdArray


foldl : (a -> b -> b) -> b -> IdArray k a -> b
foldl foldFunc startingValue (IdArray array) =
    Array.foldl foldFunc startingValue array


foldr : (a -> b -> b) -> b -> IdArray k a -> b
foldr foldFunc startingValue (IdArray array) =
    Array.foldr foldFunc startingValue array


empty : IdArray k a
empty =
    IdArray Array.empty


length : IdArray k v -> Int
length (IdArray array) =
    Array.length array


toList : IdArray k v -> List v
toList (IdArray array) =
    Array.toList array


fromList : List v -> IdArray k v
fromList list =
    Array.fromList list |> IdArray


initialize : Int -> (Int -> v) -> IdArray k v
initialize len fn =
    Array.initialize len fn |> IdArray
