module SeqDictHelper exposing (addItem, addList, increment)

import List.Nonempty exposing (Nonempty)
import NonemptySet exposing (NonemptySet)
import OneOrGreater exposing (OneOrGreater)
import SeqDict exposing (SeqDict)


increment : a -> SeqDict a OneOrGreater -> SeqDict a OneOrGreater
increment key dict =
    SeqDict.update
        key
        (\maybe ->
            case maybe of
                Just value ->
                    OneOrGreater.increment value |> Just

                Nothing ->
                    Just OneOrGreater.one
        )
        dict


addItem : a -> b -> SeqDict a (NonemptySet b) -> SeqDict a (NonemptySet b)
addItem key item dict =
    SeqDict.update
        key
        (\maybe ->
            case maybe of
                Just nonempty ->
                    NonemptySet.insert item nonempty |> Just

                Nothing ->
                    NonemptySet.singleton item |> Just
        )
        dict


addList : a -> b -> SeqDict a (Nonempty b) -> SeqDict a (Nonempty b)
addList key item dict =
    SeqDict.update
        key
        (\maybe ->
            case maybe of
                Just nonempty ->
                    List.Nonempty.cons item nonempty |> Just

                Nothing ->
                    List.Nonempty.singleton item |> Just
        )
        dict
