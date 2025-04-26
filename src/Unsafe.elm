module Unsafe exposing
    ( channelName
    , emailAddress
    , personName
    , url
    )

import ChannelName exposing (ChannelName)
import EmailAddress exposing (EmailAddress)
import PersonName exposing (PersonName)
import Url exposing (Url)


url : String -> Url
url urlText =
    case Url.fromString urlText of
        Just url_ ->
            url_

        Nothing ->
            unreachable 0


personName : String -> PersonName
personName a =
    case PersonName.fromString a of
        Ok b ->
            b

        Err _ ->
            unreachable 0


channelName : String -> ChannelName
channelName a =
    case ChannelName.fromString a of
        Ok b ->
            b

        Err _ ->
            unreachable 0


emailAddress : String -> EmailAddress
emailAddress a =
    case EmailAddress.fromString a of
        Just b ->
            b

        Nothing ->
            unreachable 0


{-| Be very careful when using this!
-}
unreachable : Int -> a
unreachable v =
    unreachable (causeStackOverflow v)


causeStackOverflow : Int -> Int
causeStackOverflow value =
    causeStackOverflow value + 1
