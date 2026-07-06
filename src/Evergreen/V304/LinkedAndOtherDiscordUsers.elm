module Evergreen.V304.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V304.Discord
import Evergreen.V304.DiscordUserData
import Evergreen.V304.EmailAddress
import Evergreen.V304.FileStatus
import Evergreen.V304.PersonName
import Evergreen.V304.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V304.PersonName.PersonName
    , icon : Maybe Evergreen.V304.FileStatus.FileHash
    , email : Maybe Evergreen.V304.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V304.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) Evergreen.V304.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) DiscordFrontendCurrentUser)
