module Evergreen.V299.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V299.Discord
import Evergreen.V299.DiscordUserData
import Evergreen.V299.EmailAddress
import Evergreen.V299.FileStatus
import Evergreen.V299.PersonName
import Evergreen.V299.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V299.PersonName.PersonName
    , icon : Maybe Evergreen.V299.FileStatus.FileHash
    , email : Maybe Evergreen.V299.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V299.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) Evergreen.V299.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) DiscordFrontendCurrentUser)
