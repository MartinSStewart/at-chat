module Evergreen.V381.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V381.Discord
import Evergreen.V381.DiscordUserData
import Evergreen.V381.EmailAddress
import Evergreen.V381.FileStatus
import Evergreen.V381.PersonName
import Evergreen.V381.UserColor
import Evergreen.V381.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V381.PersonName.PersonName
    , color : Evergreen.V381.UserColor.UserColor
    , icon : Maybe Evergreen.V381.FileStatus.FileHash
    , email : Maybe Evergreen.V381.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V381.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) Evergreen.V381.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) DiscordFrontendCurrentUser)
