module Evergreen.V351.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V351.Discord
import Evergreen.V351.DiscordUserData
import Evergreen.V351.EmailAddress
import Evergreen.V351.FileStatus
import Evergreen.V351.PersonName
import Evergreen.V351.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V351.PersonName.PersonName
    , icon : Maybe Evergreen.V351.FileStatus.FileHash
    , email : Maybe Evergreen.V351.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V351.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) Evergreen.V351.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) DiscordFrontendCurrentUser)
