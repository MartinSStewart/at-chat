module NonemptySet exposing
    ( NonemptySet(..)
    , singleton
    , member, size
    , fromNonemptyList, toNonemptyList, toList, fromList
    , map, toSeqSet, fromSeqSet
    , head, insert
    )

{-| A nonempty Set of unique values

Insert, remove, and query operations all take _O(log n)_ time.


# Set

@docs NonemptySet


# Build

@docs singleton


# Query

@docs member, get, size


# Update

@docs updateIfExists


# Lists

@docs keys, fromNonemptyList, toNonemptyList, toList, fromList


# Transform

@docs map, toSeqSet, fromSeqSet

-}

import List.Nonempty exposing (Nonempty(..))
import SeqSet exposing (SeqSet)


type
    NonemptySet a
    -- id and a represent the last inserted key-value pair
    = NonemptySet a (SeqSet a)


{-| Determine if a key is in a NonemptySet.
-}
member : id -> NonemptySet id -> Bool
member key (NonemptySet id set) =
    key == id || SeqSet.member key set


{-| Create a NonemptySet with one key-value pair.
-}
singleton : id -> NonemptySet id
singleton key =
    NonemptySet key SeqSet.empty



-- TRANSFORM


{-| Apply a function to all values in a NonemptySet.
-}
map : (k -> b) -> NonemptySet k -> NonemptySet b
map func (NonemptySet id set) =
    SeqSet.map func set |> NonemptySet (func id)



-- LISTS


{-| Convert a NonemptySet into an association list of key-value pairs, sorted by insertion order.
-}
toList : NonemptySet k -> List k
toList (NonemptySet id set) =
    SeqSet.foldr (\k list -> k :: list) [ id ] set


{-| Convert from a list to a NonemptySet. Returns Nothing if the list was empty
-}
fromList : List id -> Maybe (NonemptySet id)
fromList list =
    List.Nonempty.fromList list |> Maybe.map fromNonemptyList


{-| Convert to a normal SeqSet.
-}
toSeqSet : NonemptySet id -> SeqSet id
toSeqSet (NonemptySet id idSet) =
    SeqSet.insert id idSet


{-| Try converting from an SeqSet (Id to) a NonemptyIdSet
-}
fromSeqSet : SeqSet id -> Maybe (NonemptySet id)
fromSeqSet set =
    SeqSet.toList set |> fromList


{-| Convert a NonemptySet into a nonempty association list of key-value pairs, sorted by keys.
-}
toNonemptyList : NonemptySet k -> Nonempty k
toNonemptyList (NonemptySet id set) =
    SeqSet.foldr (\k list -> List.Nonempty.cons k list) (Nonempty id []) set


{-| Convert an nonempty association list into a NonemptySet.
-}
fromNonemptyList : Nonempty id -> NonemptySet id
fromNonemptyList (Nonempty id rest) =
    List.foldl (\k set -> insert k set) (singleton id) rest


{-| Insert a key value pair into the NonemptySet
-}
insert : id -> NonemptySet id -> NonemptySet id
insert id (NonemptySet id2 set) =
    if id == id2 then
        NonemptySet id2 set

    else if SeqSet.member id set then
        NonemptySet id2 (SeqSet.insert id set)

    else
        NonemptySet id (SeqSet.insert id2 set)


{-| Get the size of the NonemptySet (guaranteed to be greater than 0)
-}
size : NonemptySet id -> Int
size (NonemptySet _ set) =
    SeqSet.size set + 1


{-| Get the most recently inserted item.
-}
head : NonemptySet id -> id
head (NonemptySet a _) =
    a
