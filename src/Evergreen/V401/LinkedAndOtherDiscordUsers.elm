module Evergreen.V401.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V401.Discord
import Evergreen.V401.DiscordUserData
import Evergreen.V401.EmailAddress
import Evergreen.V401.FileStatus
import Evergreen.V401.PersonName
import Evergreen.V401.UserColor
import Evergreen.V401.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V401.PersonName.PersonName
    , color : Evergreen.V401.UserColor.UserColor
    , icon : Maybe Evergreen.V401.FileStatus.FileHash
    , email : Maybe Evergreen.V401.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V401.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) Evergreen.V401.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) DiscordFrontendCurrentUser)
