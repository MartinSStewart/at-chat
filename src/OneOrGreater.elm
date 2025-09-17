module OneOrGreater exposing (OneOrGreater, fromInt, increment, one, plus, toInt)


type OneOrGreater
    = OneOrGreater Int


one : OneOrGreater
one =
    OneOrGreater 1


increment : OneOrGreater -> OneOrGreater
increment (OneOrGreater a) =
    OneOrGreater (a + 1)


toInt : OneOrGreater -> Int
toInt (OneOrGreater a) =
    a


fromInt : Int -> Maybe OneOrGreater
fromInt int =
    if int > 0 then
        OneOrGreater int |> Just

    else
        Nothing


plus : OneOrGreater -> OneOrGreater -> OneOrGreater
plus (OneOrGreater a) (OneOrGreater b) =
    OneOrGreater (a + b)
