module NonemptyExtra exposing (appendList, minimumBy)

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
