module Evergreen.V308.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V308.Discord
import Evergreen.V308.DiscordUserData
import Evergreen.V308.EmailAddress
import Evergreen.V308.FileStatus
import Evergreen.V308.PersonName
import Evergreen.V308.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V308.PersonName.PersonName
    , icon : Maybe Evergreen.V308.FileStatus.FileHash
    , email : Maybe Evergreen.V308.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V308.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) Evergreen.V308.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) DiscordFrontendCurrentUser)
