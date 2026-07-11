module Evergreen.V312.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V312.Discord
import Evergreen.V312.DiscordUserData
import Evergreen.V312.EmailAddress
import Evergreen.V312.FileStatus
import Evergreen.V312.PersonName
import Evergreen.V312.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V312.PersonName.PersonName
    , icon : Maybe Evergreen.V312.FileStatus.FileHash
    , email : Maybe Evergreen.V312.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V312.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) Evergreen.V312.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) DiscordFrontendCurrentUser)
