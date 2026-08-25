module IdArray exposing
    ( IdArray(..)
    , append
    , empty
    , foldl
    , fromArray
    , fromList
    , get
    , isEmpty
    , last
    , length
    , map
    , nextId
    , push
    , set
    , slice
    , toArray
    , toList
    , update
    )

{-| Just a normal array except you use an Id instead of a raw Int to access indices.
-}

import Array exposing (Array)
import Array.Extra
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


map : (Id k -> v1 -> v2) -> IdArray k v1 -> IdArray k v2
map mapFunc (IdArray array) =
    Array.indexedMap (\index value -> mapFunc (Id.fromInt index) value) array |> IdArray


update : Id k -> (v -> v) -> IdArray k v -> IdArray k v
update key updateFunc (IdArray array) =
    Array.Extra.update (Id.toInt key) updateFunc array |> IdArray


foldl : (a -> b -> b) -> b -> IdArray k a -> b
foldl foldFunc startingValue (IdArray array) =
    Array.foldl foldFunc startingValue array


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


fromArray : Array v -> IdArray k v
fromArray =
    IdArray


fromList : List v -> IdArray k v
fromList list =
    Array.fromList list |> IdArray


push : v -> IdArray k v -> IdArray k v
push value (IdArray array) =
    Array.push value array |> IdArray


{-| Note that this will cause the second IdArray's IDs to shift.
-}
append : IdArray k v -> IdArray k v -> IdArray k v
append (IdArray arrayA) (IdArray arrayB) =
    Array.append arrayA arrayB |> IdArray


slice : Id k -> Id k -> IdArray k v -> IdArray k v
slice start end (IdArray array) =
    Array.slice (Id.toInt start) (Id.toInt end) array |> IdArray


nextId : IdArray k v -> Id k
nextId idArray =
    length idArray |> Id.fromInt
