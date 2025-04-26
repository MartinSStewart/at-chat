module Id exposing
    ( ChannelId(..)
    , GuildId(..)
    , Id(..)
    , UserId(..)
    , fromString
    , toString
    )


type UserId
    = UserId Never


type GuildId
    = GuildId Never


type ChannelId
    = ChannelId Never


type Id a
    = Id String


fromString : String -> Id a
fromString =
    Id


toString : Id a -> String
toString (Id a) =
    a
