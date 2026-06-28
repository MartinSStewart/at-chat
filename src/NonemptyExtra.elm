module NonemptyExtra exposing (appendList, maximumBy, minimumBy, set, update)

import List.Extra
import List.Nonempty exposing (Nonempty(..))


appendList : Nonempty a -> List a -> Nonempty a
appendList (Nonempty head tail) list =
    Nonempty head (tail ++ list)


minimumBy : (a -> comparable) -> Nonempty a -> a
minimumBy minFunc (Nonempty head tail) =
    case List.Extra.minimumBy minFunc (head :: tail) of
        Just minimum ->
            minimum

        Nothing ->
            head


maximumBy : (a -> comparable) -> Nonempty a -> a
maximumBy maxFunc (Nonempty head tail) =
    case List.Extra.maximumBy maxFunc (head :: tail) of
        Just minimum ->
            minimum

        Nothing ->
            head


{-| Update value at index position. Index is modBy so that it wraps around if it's larger than the list.
-}
update : Int -> (a -> a) -> Nonempty a -> Nonempty a
update int updateFunc nonempty =
    let
        index : Int
        index =
            modBy (List.Nonempty.length nonempty) int
    in
    List.Nonempty.indexedMap
        (\i value ->
            if i == index then
                updateFunc value

            else
                value
        )
        nonempty


{-| Set value at index position. Index is modBy so that it wraps around if it's larger than the list.
-}
set : Int -> a -> Nonempty a -> Nonempty a
set int value nonempty =
    update int (\_ -> value) nonempty
