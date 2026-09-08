module Evergreen.V373.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V373.Discord
import Evergreen.V373.DiscordUserData
import Evergreen.V373.EmailAddress
import Evergreen.V373.FileStatus
import Evergreen.V373.PersonName
import Evergreen.V373.UserColor
import Evergreen.V373.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V373.PersonName.PersonName
    , color : Evergreen.V373.UserColor.UserColor
    , icon : Maybe Evergreen.V373.FileStatus.FileHash
    , email : Maybe Evergreen.V373.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V373.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) Evergreen.V373.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) DiscordFrontendCurrentUser)
