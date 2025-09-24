module OneOrGreater exposing (OneOrGreater(..), fromInt, increment, one, plus, toInt)

{-| A integer that's guaranteed to be 1 or a value greater than 1
-}


{-| OpaqueVariants
-}
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
