module NonemptyExtra exposing (appendList)

import List.Nonempty exposing (Nonempty(..))


appendList : Nonempty a -> List a -> Nonempty a
appendList (Nonempty head tail) list =
    Nonempty head (tail ++ list)
