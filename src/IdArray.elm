module IdArray exposing
    ( IdArray(..)
    , empty
    , foldl
    , foldr
    , fromList
    , get
    , initialize
    , isEmpty
    , last
    , length
    , push
    , set
    , slice
    , toArray
    , toList
    )

{-| Just a normal array except you use an Id instead of a raw Int to access indices.
-}

import Array exposing (Array)
import Id exposing (Id)


{-| OpaqueVariants
-}
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


isEmpty : IdArray k v -> Bool
isEmpty (IdArray array) =
    Array.isEmpty array


last : IdArray k v -> Maybe v
last (IdArray array) =
    Array.get (Array.length array - 1) array


toList : IdArray k v -> List v
toList (IdArray array) =
    Array.toList array


toArray : IdArray k v -> Array v
toArray (IdArray array) =
    array


fromList : List v -> IdArray k v
fromList list =
    Array.fromList list |> IdArray


initialize : Int -> (Int -> v) -> IdArray k v
initialize len fn =
    Array.initialize len fn |> IdArray


push : v -> IdArray k v -> IdArray k v
push value (IdArray array) =
    Array.push value array |> IdArray


slice : Id k -> Id k -> IdArray k v -> IdArray k v
slice start end (IdArray array) =
    Array.slice (Id.toInt start) (Id.toInt end) array |> IdArray
