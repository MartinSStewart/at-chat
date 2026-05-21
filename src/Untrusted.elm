module Untrusted exposing
    ( Untrusted(..)
    , dmChannelId
    , emailAddress
    , untrust
    )

import DmChannel exposing (DmChannelId)
import EmailAddress exposing (EmailAddress)


{-| We can't be sure a value we got from the frontend hasn't been tampered with.
In cases where an opaque type uses code to give some kind of guarantee (for example
PersonName makes sure a person's name follows certain character restrictions) we wrap the value in Unstrusted to
make sure we don't forget to validate the value again on the backend.
-}
type Untrusted a
    = Untrusted a


emailAddress : Untrusted EmailAddress -> Maybe EmailAddress
emailAddress (Untrusted a) =
    EmailAddress.toString a |> EmailAddress.fromString


dmChannelId : Untrusted DmChannelId -> DmChannelId
dmChannelId (Untrusted a) =
    let
        ( userIdA, userIdB ) =
            DmChannel.userIdsFromChannelId a
    in
    DmChannel.channelIdFromUserIds userIdA userIdB


untrust : a -> Untrusted a
untrust =
    Untrusted
