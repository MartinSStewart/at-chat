module Evergreen.V295.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V295.Discord
import Evergreen.V295.DiscordUserData
import Evergreen.V295.EmailAddress
import Evergreen.V295.FileStatus
import Evergreen.V295.PersonName
import Evergreen.V295.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V295.PersonName.PersonName
    , icon : Maybe Evergreen.V295.FileStatus.FileHash
    , email : Maybe Evergreen.V295.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V295.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) Evergreen.V295.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) DiscordFrontendCurrentUser)
