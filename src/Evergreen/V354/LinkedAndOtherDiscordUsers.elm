module Evergreen.V354.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V354.Discord
import Evergreen.V354.DiscordUserData
import Evergreen.V354.EmailAddress
import Evergreen.V354.FileStatus
import Evergreen.V354.PersonName
import Evergreen.V354.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V354.PersonName.PersonName
    , icon : Maybe Evergreen.V354.FileStatus.FileHash
    , email : Maybe Evergreen.V354.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V354.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) Evergreen.V354.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) DiscordFrontendCurrentUser)
