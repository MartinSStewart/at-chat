module Evergreen.V347.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V347.Discord
import Evergreen.V347.DiscordUserData
import Evergreen.V347.EmailAddress
import Evergreen.V347.FileStatus
import Evergreen.V347.PersonName
import Evergreen.V347.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V347.PersonName.PersonName
    , icon : Maybe Evergreen.V347.FileStatus.FileHash
    , email : Maybe Evergreen.V347.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V347.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) Evergreen.V347.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) DiscordFrontendCurrentUser)
