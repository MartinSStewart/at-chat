module Evergreen.V395.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V395.Discord
import Evergreen.V395.DiscordUserData
import Evergreen.V395.EmailAddress
import Evergreen.V395.FileStatus
import Evergreen.V395.PersonName
import Evergreen.V395.UserColor
import Evergreen.V395.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V395.PersonName.PersonName
    , color : Evergreen.V395.UserColor.UserColor
    , icon : Maybe Evergreen.V395.FileStatus.FileHash
    , email : Maybe Evergreen.V395.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V395.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) Evergreen.V395.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) DiscordFrontendCurrentUser)
