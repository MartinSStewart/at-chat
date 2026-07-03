module Evergreen.V301.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V301.Discord
import Evergreen.V301.DiscordUserData
import Evergreen.V301.EmailAddress
import Evergreen.V301.FileStatus
import Evergreen.V301.PersonName
import Evergreen.V301.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V301.PersonName.PersonName
    , icon : Maybe Evergreen.V301.FileStatus.FileHash
    , email : Maybe Evergreen.V301.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V301.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) Evergreen.V301.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) DiscordFrontendCurrentUser)
