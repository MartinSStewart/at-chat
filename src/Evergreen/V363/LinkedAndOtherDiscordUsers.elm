module Evergreen.V363.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V363.Discord
import Evergreen.V363.DiscordUserData
import Evergreen.V363.EmailAddress
import Evergreen.V363.FileStatus
import Evergreen.V363.PersonName
import Evergreen.V363.UserColor
import Evergreen.V363.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V363.PersonName.PersonName
    , color : Evergreen.V363.UserColor.UserColor
    , icon : Maybe Evergreen.V363.FileStatus.FileHash
    , email : Maybe Evergreen.V363.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V363.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) Evergreen.V363.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) DiscordFrontendCurrentUser)
