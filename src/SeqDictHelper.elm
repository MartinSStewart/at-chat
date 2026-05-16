module SeqDictHelper exposing (increment)

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



--
--addItem :  a -> SeqDict a OneOrGreater -> SeqDict a OneOrGreater
--addItem a seqDict =
--
