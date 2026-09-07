module Evergreen.V370.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V370.Discord
import Evergreen.V370.DiscordUserData
import Evergreen.V370.EmailAddress
import Evergreen.V370.FileStatus
import Evergreen.V370.PersonName
import Evergreen.V370.UserColor
import Evergreen.V370.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V370.PersonName.PersonName
    , color : Evergreen.V370.UserColor.UserColor
    , icon : Maybe Evergreen.V370.FileStatus.FileHash
    , email : Maybe Evergreen.V370.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V370.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) Evergreen.V370.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) DiscordFrontendCurrentUser)
