module Evergreen.V313.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V313.Discord
import Evergreen.V313.DiscordUserData
import Evergreen.V313.EmailAddress
import Evergreen.V313.FileStatus
import Evergreen.V313.PersonName
import Evergreen.V313.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V313.PersonName.PersonName
    , icon : Maybe Evergreen.V313.FileStatus.FileHash
    , email : Maybe Evergreen.V313.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V313.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) Evergreen.V313.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) DiscordFrontendCurrentUser)
