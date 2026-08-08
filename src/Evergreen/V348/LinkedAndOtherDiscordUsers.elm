module Evergreen.V348.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V348.Discord
import Evergreen.V348.DiscordUserData
import Evergreen.V348.EmailAddress
import Evergreen.V348.FileStatus
import Evergreen.V348.PersonName
import Evergreen.V348.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V348.PersonName.PersonName
    , icon : Maybe Evergreen.V348.FileStatus.FileHash
    , email : Maybe Evergreen.V348.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V348.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) Evergreen.V348.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) DiscordFrontendCurrentUser)
