module Evergreen.V345.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V345.Discord
import Evergreen.V345.DiscordUserData
import Evergreen.V345.EmailAddress
import Evergreen.V345.FileStatus
import Evergreen.V345.PersonName
import Evergreen.V345.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V345.PersonName.PersonName
    , icon : Maybe Evergreen.V345.FileStatus.FileHash
    , email : Maybe Evergreen.V345.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V345.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) Evergreen.V345.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) DiscordFrontendCurrentUser)
