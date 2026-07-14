module Evergreen.V323.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V323.Discord
import Evergreen.V323.DiscordUserData
import Evergreen.V323.EmailAddress
import Evergreen.V323.FileStatus
import Evergreen.V323.PersonName
import Evergreen.V323.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V323.PersonName.PersonName
    , icon : Maybe Evergreen.V323.FileStatus.FileHash
    , email : Maybe Evergreen.V323.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V323.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) Evergreen.V323.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) DiscordFrontendCurrentUser)
