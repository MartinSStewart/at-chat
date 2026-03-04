module CodecExtra exposing
    ( discordId
    , nonempty
    , nonemptySet
    , nonemptyString
    , oneToOne
    , quantityInt
    , seqDict
    , timePosix
    )

import Codec exposing (Codec)
import Discord.Id
import Effect.Time as Time
import List.Nonempty exposing (Nonempty)
import NonemptySet exposing (NonemptySet)
import OneToOne exposing (OneToOne)
import Quantity exposing (Quantity)
import SeqDict exposing (SeqDict)
import String.Nonempty exposing (NonemptyString(..))
import UInt64 exposing (UInt64)


quantityInt : Codec (Quantity Int units)
quantityInt =
    Codec.map Quantity.unsafe Quantity.unwrap Codec.int


timePosix : Codec Time.Posix
timePosix =
    Codec.map Time.millisToPosix Time.posixToMillis Codec.int


discordId : Codec (Discord.Id.Id a)
discordId =
    Codec.map Discord.Id.fromUInt64 Discord.Id.toUInt64 uint64


uint64 : Codec UInt64
uint64 =
    Codec.andThen
        (\text ->
            case UInt64.fromString text of
                Just uint ->
                    Codec.succeed uint

                Nothing ->
                    Codec.fail "Not a valid Discord ID"
        )
        UInt64.toString
        Codec.string


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


seqDict : Codec k -> Codec v -> Codec (SeqDict k v)
seqDict keyCodec valueCodec =
    Codec.map
        SeqDict.fromList
        SeqDict.toList
        (Codec.list (Codec.tuple keyCodec valueCodec))


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


nonemptySet : Codec a -> Codec (NonemptySet a)
nonemptySet itemCodec =
    Codec.map
        NonemptySet.fromNonemptyList
        NonemptySet.toNonemptyList
        (nonempty itemCodec)


oneToOne : Codec a -> Codec b -> Codec (OneToOne a b)
oneToOne keyCodec valueCodec =
    Codec.map
        OneToOne.fromList
        OneToOne.toList
        (Codec.list (Codec.tuple keyCodec valueCodec))
