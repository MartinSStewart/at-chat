module DmChannelId exposing
    ( DmChannelId(..)
    , GuildOrFullDmId(..)
    , fromString
    , fromUserIds
    , otherUserId
    , toString
    , toUserIds
    )

import Id exposing (ChannelId, GuildId, Id, UserId)


{-| OpaqueVariants
-}
type DmChannelId
    = DmChannelId (Id UserId) (Id UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Id GuildId) (Id ChannelId)
    | GuildOrFullDmId_Dm DmChannelId


fromUserIds : Id UserId -> Id UserId -> DmChannelId
fromUserIds userIdA userIdB =
    DmChannelId
        (min (Id.toInt userIdA) (Id.toInt userIdB) |> Id.fromInt)
        (max (Id.toInt userIdA) (Id.toInt userIdB) |> Id.fromInt)


toUserIds : DmChannelId -> ( Id UserId, Id UserId )
toUserIds (DmChannelId userIdA userIdB) =
    ( userIdA, userIdB )


toString : DmChannelId -> String
toString (DmChannelId userIdA userIdB) =
    Id.toString userIdA ++ "-" ++ Id.toString userIdB


fromString : String -> Result () DmChannelId
fromString text =
    case String.split "-" text of
        [ idA, idB ] ->
            case ( Id.fromString idA, Id.fromString idB ) of
                ( Just idA2, Just idB2 ) ->
                    fromUserIds idA2 idB2 |> Ok

                _ ->
                    Err ()

        _ ->
            Err ()


otherUserId : Id UserId -> DmChannelId -> Maybe (Id UserId)
otherUserId userId (DmChannelId userIdA userIdB) =
    if userId == userIdA then
        Just userIdB

    else if userId == userIdB then
        Just userIdA

    else
        Nothing
