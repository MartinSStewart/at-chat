module SeqDictHelper exposing (addToDict, addToList, addToSet, increment, updateOrInsert)

import List.Nonempty exposing (Nonempty)
import NonemptyDict exposing (NonemptyDict)
import NonemptySet exposing (NonemptySet)
import OneOrGreater exposing (OneOrGreater)
import SeqDict exposing (SeqDict)


updateOrInsert : a -> (Maybe b -> b) -> SeqDict a b -> SeqDict a b
updateOrInsert a updateOrInsertFunc dict =
    SeqDict.update a (\maybe -> updateOrInsertFunc maybe |> Just) dict


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


addToSet : a -> b -> SeqDict a (NonemptySet b) -> SeqDict a (NonemptySet b)
addToSet key item dict =
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


addToList : a -> b -> SeqDict a (Nonempty b) -> SeqDict a (Nonempty b)
addToList key item dict =
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


addToDict : a -> b -> c -> SeqDict a (NonemptyDict b c) -> SeqDict a (NonemptyDict b c)
addToDict outerKey innerKey value voiceChats =
    SeqDict.update
        outerKey
        (\maybe ->
            case maybe of
                Just nonempty ->
                    NonemptyDict.insert innerKey value nonempty |> Just

                Nothing ->
                    NonemptyDict.singleton innerKey value |> Just
        )
        voiceChats
