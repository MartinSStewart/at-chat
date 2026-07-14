module Evergreen.V319.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V319.Discord
import Evergreen.V319.DiscordUserData
import Evergreen.V319.EmailAddress
import Evergreen.V319.FileStatus
import Evergreen.V319.PersonName
import Evergreen.V319.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V319.PersonName.PersonName
    , icon : Maybe Evergreen.V319.FileStatus.FileHash
    , email : Maybe Evergreen.V319.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V319.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) Evergreen.V319.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) DiscordFrontendCurrentUser)
