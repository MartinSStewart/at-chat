module Evergreen.V317.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V317.Discord
import Evergreen.V317.DiscordUserData
import Evergreen.V317.EmailAddress
import Evergreen.V317.FileStatus
import Evergreen.V317.PersonName
import Evergreen.V317.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V317.PersonName.PersonName
    , icon : Maybe Evergreen.V317.FileStatus.FileHash
    , email : Maybe Evergreen.V317.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V317.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) Evergreen.V317.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) DiscordFrontendCurrentUser)
