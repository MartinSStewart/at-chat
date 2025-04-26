module CodecExtra exposing
    ( clientId
    , email
    , nonempty
    , nonemptyDict
    , nonemptyString
    , quantityInt
    , seqDict
    , seqSet
    , sessionId
    , url
    )

import Codec exposing (Codec)
import Effect.Lamdera as Lamdera exposing (ClientId, SessionId)
import EmailAddress exposing (EmailAddress)
import List.Nonempty exposing (Nonempty)
import NonemptyDict exposing (NonemptyDict)
import Quantity exposing (Quantity)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import String.Nonempty exposing (NonemptyString)
import Time
import Url exposing (Url)


nonempty : Codec a -> Codec (Nonempty a)
nonempty valueCodec =
    Codec.andThen
        (\list ->
            case List.Nonempty.fromList list of
                Just a ->
                    Codec.succeed a

                Nothing ->
                    Codec.fail "List must be nonempty"
        )
        List.Nonempty.toList
        (Codec.list valueCodec)


nonemptyString : Codec NonemptyString
nonemptyString =
    Codec.andThen
        (\text ->
            case String.Nonempty.fromString text of
                Just a ->
                    Codec.succeed a

                Nothing ->
                    Codec.fail "String must be nonempty"
        )
        String.Nonempty.toString
        Codec.string


seqDict : Codec k -> Codec v -> Codec (SeqDict k v)
seqDict keyCodec valueCodec =
    Codec.map
        SeqDict.fromList
        SeqDict.toList
        (Codec.list (Codec.tuple keyCodec valueCodec))


nonemptyDict : Codec k -> Codec v -> Codec (NonemptyDict k v)
nonemptyDict keyCodec valueCodec =
    Codec.andThen
        (\list ->
            case NonemptyDict.fromList list of
                Just dict ->
                    Codec.succeed dict

                Nothing ->
                    Codec.fail "Expected dict to contain at least one item"
        )
        NonemptyDict.toList
        (Codec.list (Codec.tuple keyCodec valueCodec))


url : Codec Url
url =
    Codec.andThen
        (\text ->
            case Url.fromString text of
                Just a ->
                    Codec.succeed a

                Nothing ->
                    Codec.fail (text ++ " is an invalid url")
        )
        Url.toString
        Codec.string


seqSet : Codec a -> Codec (SeqSet a)
seqSet codec =
    Codec.map SeqSet.fromList SeqSet.toList (Codec.list codec)


email : Codec EmailAddress
email =
    Codec.andThen
        (\text ->
            case EmailAddress.fromString text of
                Just a ->
                    Codec.succeed a

                Nothing ->
                    Codec.fail (text ++ " is not a valid email")
        )
        EmailAddress.toString
        Codec.string


sessionId : Codec SessionId
sessionId =
    Codec.map Lamdera.sessionIdFromString Lamdera.sessionIdToString Codec.string


clientId : Codec ClientId
clientId =
    Codec.map Lamdera.clientIdFromString Lamdera.clientIdToString Codec.string


quantityInt : Codec (Quantity Int units)
quantityInt =
    Codec.map Quantity.unsafe Quantity.unwrap Codec.int
