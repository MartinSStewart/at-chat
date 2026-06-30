module Evergreen.V297.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V297.Discord
import Evergreen.V297.DiscordUserData
import Evergreen.V297.EmailAddress
import Evergreen.V297.FileStatus
import Evergreen.V297.PersonName
import Evergreen.V297.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V297.PersonName.PersonName
    , icon : Maybe Evergreen.V297.FileStatus.FileHash
    , email : Maybe Evergreen.V297.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V297.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) Evergreen.V297.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) DiscordFrontendCurrentUser)
