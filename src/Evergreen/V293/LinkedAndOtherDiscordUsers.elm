module Evergreen.V293.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V293.Discord
import Evergreen.V293.DiscordUserData
import Evergreen.V293.EmailAddress
import Evergreen.V293.FileStatus
import Evergreen.V293.PersonName
import Evergreen.V293.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V293.PersonName.PersonName
    , icon : Maybe Evergreen.V293.FileStatus.FileHash
    , email : Maybe Evergreen.V293.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V293.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) Evergreen.V293.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) DiscordFrontendCurrentUser)
