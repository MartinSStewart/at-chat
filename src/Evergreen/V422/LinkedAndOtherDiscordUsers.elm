module Evergreen.V422.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V422.Discord
import Evergreen.V422.DiscordUserData
import Evergreen.V422.EmailAddress
import Evergreen.V422.FileStatus
import Evergreen.V422.PersonName
import Evergreen.V422.UserColor
import Evergreen.V422.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V422.PersonName.PersonName
    , color : Evergreen.V422.UserColor.UserColor
    , icon : Maybe Evergreen.V422.FileStatus.FileHash
    , email : Maybe Evergreen.V422.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V422.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) Evergreen.V422.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) DiscordFrontendCurrentUser)
