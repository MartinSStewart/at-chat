module Evergreen.V394.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V394.Discord
import Evergreen.V394.DiscordUserData
import Evergreen.V394.EmailAddress
import Evergreen.V394.FileStatus
import Evergreen.V394.PersonName
import Evergreen.V394.UserColor
import Evergreen.V394.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V394.PersonName.PersonName
    , color : Evergreen.V394.UserColor.UserColor
    , icon : Maybe Evergreen.V394.FileStatus.FileHash
    , email : Maybe Evergreen.V394.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V394.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) Evergreen.V394.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) DiscordFrontendCurrentUser)
