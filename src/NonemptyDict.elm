module NonemptyDict exposing
    ( NonemptyDict(..)
    , singleton
    , member, get, size
    , updateIfExists
    , keys, values, fromNonemptyList, toNonemptyList, toList, fromList
    , map, toSeqDict, fromSeqDict
    , any, foldl, foldr, head, insert, updateOrInsert
    )

{-| A dictionary mapping unique keys to values.

Insert, remove, and query operations all take _O(log n)_ time.


# Dictionaries

@docs NonemptyDict


# Build

@docs singleton


# Query

@docs member, get, size


# Update

@docs updateIfExists


# Lists

@docs keys, values, fromNonemptyList, toNonemptyList, toList, fromList


# Transform

@docs map, toSeqDict, fromSeqDict

-}

import List.Nonempty exposing (Nonempty(..))
import SeqDict exposing (SeqDict)


type
    NonemptyDict id a
    -- id and a represent the last inserted key-value pair
    = NonemptyDict id a (SeqDict id a)


{-| Get the value associated with a key. If the key is not found, return
`Nothing`. This is useful when you are not sure if a key will be in the
dictionary.

    animals = fromList [ ("Tom", Cat), ("Jerry", Mouse) ]

    get "Tom"   animals == Just Cat
    get "Jerry" animals == Just Mouse
    get "Spike" animals == Nothing

-}
get : id -> NonemptyDict id v -> Maybe v
get targetKey (NonemptyDict id a dict) =
    if targetKey == id then
        Just a

    else
        SeqDict.get targetKey dict


{-| Determine if a key is in a dictionary.
-}
member : id -> NonemptyDict id v -> Bool
member key (NonemptyDict id _ dict) =
    key == id || SeqDict.member key dict


{-| Create a dictionary with one key-value pair.
-}
singleton : id -> v -> NonemptyDict id v
singleton key value =
    NonemptyDict key value SeqDict.empty



-- TRANSFORM


{-| Apply a function to all values in a dictionary.
-}
map : (k -> a -> b) -> NonemptyDict k a -> NonemptyDict k b
map func (NonemptyDict id a dict) =
    SeqDict.map func dict |> NonemptyDict id (func id a)


{-| -}
updateIfExists : id -> (v -> v) -> NonemptyDict id v -> NonemptyDict id v
updateIfExists targetKey alter (NonemptyDict id a dict) =
    if targetKey == id then
        NonemptyDict id (alter a) dict

    else
        SeqDict.updateIfExists targetKey alter dict |> NonemptyDict id a


{-| Update the value if it exists, otherwise insert a new value.
-}
updateOrInsert : id -> (Maybe v -> v) -> NonemptyDict id v -> NonemptyDict id v
updateOrInsert targetKey alter dict =
    case get targetKey dict of
        Just value ->
            updateIfExists targetKey (\_ -> alter (Just value)) dict

        Nothing ->
            insert targetKey (alter Nothing) dict



-- LISTS


{-| Get all of the keys in a dictionary, sorted by insertion order
-}
keys : NonemptyDict k v -> Nonempty k
keys (NonemptyDict id _ dict) =
    Nonempty id (SeqDict.keys dict)


{-| Get all of the values in a dictionary, sorted by insertion order
-}
values : NonemptyDict k v -> Nonempty v
values (NonemptyDict _ v dict) =
    Nonempty v (SeqDict.values dict)


{-| Convert a dictionary into an association list of key-value pairs, sorted by insertion order.
-}
toList : NonemptyDict k v -> List ( k, v )
toList (NonemptyDict id a dict) =
    SeqDict.foldr (\k v list -> ( k, v ) :: list) [ ( id, a ) ] dict


{-| Convert from a list to a NonemptyDict. Returns Nothing if the list was empty
-}
fromList : List ( id, v ) -> Maybe (NonemptyDict id v)
fromList list =
    List.Nonempty.fromList list |> Maybe.map fromNonemptyList


{-| Convert to a normal SeqDict.
-}
toSeqDict : NonemptyDict id v -> SeqDict id v
toSeqDict (NonemptyDict id a idDict) =
    SeqDict.insert id a idDict


{-| Try converting from an SeqDict (Id to) a NonemptyIdDict
-}
fromSeqDict : SeqDict id v -> Maybe (NonemptyDict id v)
fromSeqDict dict =
    SeqDict.toList dict |> fromList


{-| Convert a dictionary into a nonempty association list of key-value pairs, sorted by keys.
-}
toNonemptyList : NonemptyDict k v -> Nonempty ( k, v )
toNonemptyList (NonemptyDict id a dict) =
    SeqDict.foldr (\k v list -> List.Nonempty.cons ( k, v ) list) (Nonempty ( id, a ) []) dict


{-| Convert an nonempty association list into a dictionary.
-}
fromNonemptyList : Nonempty ( id, v ) -> NonemptyDict id v
fromNonemptyList (Nonempty ( id, a ) rest) =
    List.foldl (\( k, v ) dict -> insert k v dict) (singleton id a) rest


{-| Insert a key-value pair into the dictionary. Replaces value when there is
a collision.
-}
insert : id -> v -> NonemptyDict id v -> NonemptyDict id v
insert id value (NonemptyDict id2 a dict) =
    if id == id2 then
        NonemptyDict id2 value dict

    else if SeqDict.member id dict then
        NonemptyDict id2 a (SeqDict.insert id value dict)

    else
        NonemptyDict id value (SeqDict.insert id2 a dict)


{-| Get the size of the dictionary (guaranteed to be greater than 0)
-}
size : NonemptyDict id v -> Int
size (NonemptyDict _ _ dict) =
    SeqDict.size dict + 1


any : (k -> v -> Bool) -> NonemptyDict k v -> Bool
any f (NonemptyDict k1 v1 dict) =
    f k1 v1 || SeqDict.foldl (\k v acc -> acc || f k v) False dict


foldl : (k -> v -> acc -> acc) -> acc -> NonemptyDict k v -> acc
foldl f acc (NonemptyDict k1 v1 dict) =
    SeqDict.foldl f (f k1 v1 acc) dict


foldr : (k -> v -> acc -> acc) -> acc -> NonemptyDict k v -> acc
foldr f acc (NonemptyDict k1 v1 dict) =
    f k1 v1 (SeqDict.foldr f acc dict)


{-| Get the most recently inserted item.
-}
head : NonemptyDict k v -> ( k, v )
head (NonemptyDict k v _) =
    ( k, v )
