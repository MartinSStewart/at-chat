module Discord.Id exposing
    ( AchievementId
    , ApplicationId
    , AttachmentId
    , ChannelId
    , CustomEmojiId
    , GuildId
    , Id(..)
    , MessageId
    , OverwriteId
    , PrivateChannelId
    , RoleId
    , StickerId
    , StickerPackId
    , TagId
    , TeamId
    , UserId
    , WebhookId
    , decodeId
    , encodeId
    , fromString
    , fromUInt64
    , toString
    , toUInt64
    )

{-| In Discord's documentation these are called snowflakes. They are always 64bit positive integers.
-}

import Json.Decode as JD
import Json.Encode as JE
import UInt64 exposing (UInt64)


type Id idType
    = Id UInt64


type MessageId
    = MessageId Never


type UserId
    = UserId Never


type RoleId
    = RoleId Never


type ChannelId
    = ChannelId Never


{-| Only for user tokens. Bots can't access private channels
-}
type PrivateChannelId
    = PrivateChannelId Never


type GuildId
    = GuildId Never


type WebhookId
    = WebhookId Never


type AttachmentId
    = AttachmentId Never


type CustomEmojiId
    = CustomEmojiId Never


type ApplicationId
    = ApplicationId Never


type OverwriteId
    = OverwriteId Never


type TeamId
    = TeamId Never


type AchievementId
    = AchievementId Never


type StickerId
    = StickerId Never


type StickerPackId
    = StickerPackId Never


type TagId
    = TagId Never


encodeId : Id idType -> JE.Value
encodeId id =
    JE.string (toString id)


decodeId : JD.Decoder (Id idType)
decodeId =
    JD.andThen
        (\text ->
            case fromString text of
                Just id ->
                    JD.succeed id

                Nothing ->
                    JD.fail "Invalid snowflake ID."
        )
        JD.string


toString : Id idType -> String
toString id =
    toUInt64 id |> UInt64.toString


fromString : String -> Maybe (Id idType)
fromString text =
    case UInt64.fromString text of
        Just uint ->
            Id uint |> Just

        Nothing ->
            Nothing


toUInt64 : Id idType -> UInt64
toUInt64 (Id id) =
    id


fromUInt64 : UInt64 -> Id idType
fromUInt64 =
    Id
