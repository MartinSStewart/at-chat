module Evergreen.V311.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V311.Discord
import Evergreen.V311.DiscordUserData
import Evergreen.V311.EmailAddress
import Evergreen.V311.FileStatus
import Evergreen.V311.PersonName
import Evergreen.V311.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V311.PersonName.PersonName
    , icon : Maybe Evergreen.V311.FileStatus.FileHash
    , email : Maybe Evergreen.V311.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V311.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) Evergreen.V311.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) DiscordFrontendCurrentUser)
