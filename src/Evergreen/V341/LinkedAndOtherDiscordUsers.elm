module Evergreen.V341.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V341.Discord
import Evergreen.V341.DiscordUserData
import Evergreen.V341.EmailAddress
import Evergreen.V341.FileStatus
import Evergreen.V341.PersonName
import Evergreen.V341.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V341.PersonName.PersonName
    , icon : Maybe Evergreen.V341.FileStatus.FileHash
    , email : Maybe Evergreen.V341.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V341.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) Evergreen.V341.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) DiscordFrontendCurrentUser)
