module Evergreen.V335.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V335.Discord
import Evergreen.V335.DiscordUserData
import Evergreen.V335.EmailAddress
import Evergreen.V335.FileStatus
import Evergreen.V335.PersonName
import Evergreen.V335.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V335.PersonName.PersonName
    , icon : Maybe Evergreen.V335.FileStatus.FileHash
    , email : Maybe Evergreen.V335.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V335.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) Evergreen.V335.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) DiscordFrontendCurrentUser)
