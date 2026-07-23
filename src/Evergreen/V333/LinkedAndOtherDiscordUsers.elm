module Evergreen.V333.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V333.Discord
import Evergreen.V333.DiscordUserData
import Evergreen.V333.EmailAddress
import Evergreen.V333.FileStatus
import Evergreen.V333.PersonName
import Evergreen.V333.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V333.PersonName.PersonName
    , icon : Maybe Evergreen.V333.FileStatus.FileHash
    , email : Maybe Evergreen.V333.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V333.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) Evergreen.V333.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) DiscordFrontendCurrentUser)
