module OneToOne exposing
    ( OneToOne(..)
    , empty, singleton, insert, removeFirst, removeSecond
    , isEmpty, memberFirst, memberSecond, first, second, size
    , toList, fromList
    )

{-| Copied from <https://github.com/WhileTruu/elm-one-to-one/blob/1.0.0/src/OneToOne.elm>

A one-to-one mapping between values. The values can be any comparable
type. This includes `Int`, `Float`, `Time`, `Char`, `String`, and tuples or
lists of comparable types.

Insert, remove, and query operations all take _O(log n)_ time.


# One-to-one correspondence

@docs OneToOne


# Build

@docs empty, singleton, insert, removeFirst, removeSecond


# Query

@docs isEmpty, memberFirst, memberSecond, first, second, size


# Lists

@docs toList, fromList

-}

import SeqDict exposing (SeqDict)


{-| OpaqueVariants. Represents a one-to-one mapping between values. So a `OneToOne String Int` is
a one-to-one mapping that lets you look up a `String` and find the associated
`Int` and vice versa.
-}
type OneToOne a b
    = OneToOne (SeqDict a b) (SeqDict b a)



-- BUILD


{-| Create an empty one-to-one mapping.

    empty --> fromList []

-}
empty : OneToOne a b
empty =
    OneToOne SeqDict.empty SeqDict.empty


{-| -}
singleton : keyA -> keyB -> OneToOne keyA keyB
singleton a b =
    OneToOne (SeqDict.singleton a b) (SeqDict.singleton b a)


{-| Insert a pair of values into a one-to-one mapping. Removes overlapping
pairs when there is a collision.

    oneToOne : OneToOne Int Int
    oneToOne =
        empty
            |> insert 1 1
            |> insert 2 1

    oneToOne --> fromList [ ( 2, 1 ) ]

-}
insert :
    keyA
    -> keyB
    -> OneToOne keyA keyB
    -> OneToOne keyA keyB
insert a b oneToOne =
    oneToOne
        |> removeFirst a
        |> removeSecond b
        |> (\(OneToOne firstToSecond secondToFirst) ->
                OneToOne
                    (SeqDict.insert a b firstToSecond)
                    (SeqDict.insert b a secondToFirst)
           )


{-| Remove a pair from a one-to-one mapping by the first value. If the pair is
not found, no changes are made.

    animalNamesToNumbers : OneToOne String Int
    animalNamesToNumbers =
        fromList [ ( "Tom", 1 ), ( "Jerry", 2 ) ]

    removeFirst "Tom" animalNamesToNumbers --> fromList [ ( "Jerry", 2 ) ]

    removeFirst "Quacker" animalNamesToNumbers --> fromList [ ( "Tom", 1 ), ( "Jerry", 2 ) ]

-}
removeFirst :
    keyA
    -> OneToOne keyA keyB
    -> OneToOne keyA keyB
removeFirst a (OneToOne firstToSecond secondToFirst) =
    OneToOne
        (SeqDict.remove a firstToSecond)
        (SeqDict.get a firstToSecond
            |> Maybe.map (\b -> SeqDict.remove b secondToFirst)
            |> Maybe.withDefault secondToFirst
        )


{-| Remove a pair from a one-to-one mapping by the second value. If the pair is
not found, no changes are made.

    animalNamesToNumbers : OneToOne String Int
    animalNamesToNumbers =
        fromList [ ( "Tom", 1 ), ( "Jerry", 2 ) ]

    removeSecond 1 animalNamesToNumbers --> fromList [ ( "Jerry", 2 ) ]

    removeSecond 3 animalNamesToNumbers --> fromList [ ( "Tom", 1 ), ( "Jerry", 2 ) ]

-}
removeSecond :
    keyB
    -> OneToOne keyA keyB
    -> OneToOne keyA keyB
removeSecond b (OneToOne firstToSecond secondToFirst) =
    OneToOne
        (SeqDict.get b secondToFirst
            |> Maybe.map (\a -> SeqDict.remove a firstToSecond)
            |> Maybe.withDefault firstToSecond
        )
        (SeqDict.remove b secondToFirst)



-- QUERY


{-| Determine if a one-to-one mapping is empty.

    isEmpty empty --> True

    isEmpty (singleton 1 1) --> False

-}
isEmpty : OneToOne a b -> Bool
isEmpty (OneToOne firstToSecond _) =
    SeqDict.isEmpty firstToSecond


{-| Determine if a first value is in a one-to-one mapping.

    memberFirst 1 (singleton 1 2) --> True

    memberFirst 2 (singleton 1 2) --> False

-}
memberFirst : keyA -> OneToOne keyA b -> Bool
memberFirst a (OneToOne firstToSecond _) =
    SeqDict.member a firstToSecond


{-| Determine if a second value is in a one-to-one mapping.

    memberSecond 2 (singleton 1 2) --> True

    memberSecond 1 (singleton 1 2) --> False

-}
memberSecond : keyB -> OneToOne a keyB -> Bool
memberSecond b (OneToOne _ secondToFirst) =
    SeqDict.member b secondToFirst


{-| Extract the first value associated with a second value. If the second value
is not found, return `Nothing`.

    animalNamesToNumbers : OneToOne String Int
    animalNamesToNumbers =
        fromList [ ( "Tom", 1 ), ( "Jerry", 2 ) ]

    first 1 animalNamesToNumbers --> Just "Tom"
    first 2 animalNamesToNumbers --> Just "Jerry"
    first 3 animalNamesToNumbers --> Nothing

-}
first : keyB -> OneToOne a keyB -> Maybe a
first b (OneToOne _ secondToFirst) =
    SeqDict.get b secondToFirst


{-| Extract the second value associated with a first value. If the first value
is not found, return `Nothing`.

    animalNamesToNumbers : OneToOne String Int
    animalNamesToNumbers =
        fromList [ ( "Tom", 1 ), ( "Jerry", 2 ) ]

    second "Tom" animalNamesToNumbers --> Just 1
    second "Jerry" animalNamesToNumbers --> Just 2
    second "Quacker" animalNamesToNumbers --> Nothing

-}
second : keyA -> OneToOne keyA b -> Maybe b
second a (OneToOne firstToSecond _) =
    SeqDict.get a firstToSecond


{-| Determine the number of pairs in a one-to-one mapping.

    animalNamesToNumbers : OneToOne String Int
    animalNamesToNumbers =
       fromList [ ( "Tom", 1 ), ( "Jerry", 2 ) ]

    size animalNamesToNumbers --> 2

-}
size : OneToOne first second -> Int
size (OneToOne firstToSecond _) =
    SeqDict.size firstToSecond



-- LISTS


{-| Convert a one-to-one mapping into an association list of pairs, sorted by
the first value.

    toList (singleton "tomato" "cabbage") --> [ ( "tomato", "cabbage" ) ]

-}
toList : OneToOne a b -> List ( a, b )
toList (OneToOne firstDict _) =
    SeqDict.toList firstDict


{-| Convert an association list into a one-to-one mapping.

    fromList [ ( "tomato", "cabbage" ) ] --> (singleton "tomato" "cabbage")

-}
fromList : List ( keyA, keyB ) -> OneToOne keyA keyB
fromList associations =
    List.foldl (\( a, b ) oneToOne -> insert a b oneToOne)
        empty
        associations
