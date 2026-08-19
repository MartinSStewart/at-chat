module Evergreen.V359.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V359.Discord
import Evergreen.V359.DiscordUserData
import Evergreen.V359.EmailAddress
import Evergreen.V359.FileStatus
import Evergreen.V359.PersonName
import Evergreen.V359.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V359.PersonName.PersonName
    , icon : Maybe Evergreen.V359.FileStatus.FileHash
    , email : Maybe Evergreen.V359.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V359.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) Evergreen.V359.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) DiscordFrontendCurrentUser)
