module Evergreen.V328.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V328.Discord
import Evergreen.V328.DiscordUserData
import Evergreen.V328.EmailAddress
import Evergreen.V328.FileStatus
import Evergreen.V328.PersonName
import Evergreen.V328.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V328.PersonName.PersonName
    , icon : Maybe Evergreen.V328.FileStatus.FileHash
    , email : Maybe Evergreen.V328.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V328.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) Evergreen.V328.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) DiscordFrontendCurrentUser)
