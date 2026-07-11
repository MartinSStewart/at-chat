module Evergreen.V315.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V315.Discord
import Evergreen.V315.DiscordUserData
import Evergreen.V315.EmailAddress
import Evergreen.V315.FileStatus
import Evergreen.V315.PersonName
import Evergreen.V315.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V315.PersonName.PersonName
    , icon : Maybe Evergreen.V315.FileStatus.FileHash
    , email : Maybe Evergreen.V315.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V315.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) Evergreen.V315.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) DiscordFrontendCurrentUser)
