module CodecExtra exposing
    ( nonempty
    , nonemptyString
    , quantityInt
    )

import Codec exposing (Codec)
import List.Nonempty exposing (Nonempty)
import Quantity exposing (Quantity)
import String.Nonempty exposing (NonemptyString(..))


quantityInt : Codec (Quantity Int units)
quantityInt =
    Codec.map Quantity.unsafe Quantity.unwrap Codec.int


nonemptyString : Codec NonemptyString
nonemptyString =
    Codec.map
        (\s ->
            case String.uncons s of
                Just ( c, rest ) ->
                    NonemptyString c rest

                Nothing ->
                    NonemptyString 'e' "rror"
        )
        (\(NonemptyString c rest) -> String.cons c rest)
        Codec.string


nonempty : Codec a -> Codec (Nonempty a)
nonempty itemCodec =
    Codec.andThen
        (\list ->
            case List.Nonempty.fromList list of
                Just nonempty2 ->
                    Codec.succeed nonempty2

                Nothing ->
                    Codec.fail "List cannot be empty"
        )
        List.Nonempty.toList
        (Codec.list itemCodec)
