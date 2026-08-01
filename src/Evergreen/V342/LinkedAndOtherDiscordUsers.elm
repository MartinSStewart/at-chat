module Evergreen.V342.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V342.Discord
import Evergreen.V342.DiscordUserData
import Evergreen.V342.EmailAddress
import Evergreen.V342.FileStatus
import Evergreen.V342.PersonName
import Evergreen.V342.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V342.PersonName.PersonName
    , icon : Maybe Evergreen.V342.FileStatus.FileHash
    , email : Maybe Evergreen.V342.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V342.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) Evergreen.V342.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) DiscordFrontendCurrentUser)
