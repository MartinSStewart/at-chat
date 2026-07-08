module OneOrGreater exposing
    ( OneOrGreater(..)
    , decrement
    , fromInt
    , fromString
    , increment
    , one
    , plus
    , seven
    , three
    , toInt
    , toString
    )

{-| A integer that's guaranteed to be 1 or a value greater than 1
-}


{-| OpaqueVariants
-}
type OneOrGreater
    = OneOrGreater Int


one : OneOrGreater
one =
    OneOrGreater 1


three : OneOrGreater
three =
    OneOrGreater 3


seven : OneOrGreater
seven =
    OneOrGreater 7


increment : OneOrGreater -> OneOrGreater
increment (OneOrGreater a) =
    OneOrGreater (a + 1)


decrement : OneOrGreater -> Maybe OneOrGreater
decrement (OneOrGreater a) =
    if a > 1 then
        OneOrGreater (a - 1) |> Just

    else
        Nothing


toInt : OneOrGreater -> Int
toInt (OneOrGreater a) =
    a


fromInt : Int -> Maybe OneOrGreater
fromInt int =
    if int > 0 then
        OneOrGreater int |> Just

    else
        Nothing


fromString : String -> Maybe OneOrGreater
fromString text =
    case String.toInt text of
        Just int ->
            fromInt int

        Nothing ->
            Nothing


plus : OneOrGreater -> OneOrGreater -> OneOrGreater
plus (OneOrGreater a) (OneOrGreater b) =
    OneOrGreater (a + b)


toString : OneOrGreater -> String
toString (OneOrGreater a) =
    String.fromInt a
