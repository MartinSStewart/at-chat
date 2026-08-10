module Evergreen.V349.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V349.Discord
import Evergreen.V349.DiscordUserData
import Evergreen.V349.EmailAddress
import Evergreen.V349.FileStatus
import Evergreen.V349.PersonName
import Evergreen.V349.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V349.PersonName.PersonName
    , icon : Maybe Evergreen.V349.FileStatus.FileHash
    , email : Maybe Evergreen.V349.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V349.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) Evergreen.V349.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) DiscordFrontendCurrentUser)
