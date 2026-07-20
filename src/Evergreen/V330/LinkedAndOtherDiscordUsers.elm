module Evergreen.V330.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V330.Discord
import Evergreen.V330.DiscordUserData
import Evergreen.V330.EmailAddress
import Evergreen.V330.FileStatus
import Evergreen.V330.PersonName
import Evergreen.V330.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V330.PersonName.PersonName
    , icon : Maybe Evergreen.V330.FileStatus.FileHash
    , email : Maybe Evergreen.V330.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V330.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) Evergreen.V330.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) DiscordFrontendCurrentUser)
