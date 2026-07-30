module Evergreen.V340.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V340.Discord
import Evergreen.V340.DiscordUserData
import Evergreen.V340.EmailAddress
import Evergreen.V340.FileStatus
import Evergreen.V340.PersonName
import Evergreen.V340.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V340.PersonName.PersonName
    , icon : Maybe Evergreen.V340.FileStatus.FileHash
    , email : Maybe Evergreen.V340.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V340.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) Evergreen.V340.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) DiscordFrontendCurrentUser)
