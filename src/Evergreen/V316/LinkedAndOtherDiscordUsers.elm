module Evergreen.V316.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V316.Discord
import Evergreen.V316.DiscordUserData
import Evergreen.V316.EmailAddress
import Evergreen.V316.FileStatus
import Evergreen.V316.PersonName
import Evergreen.V316.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V316.PersonName.PersonName
    , icon : Maybe Evergreen.V316.FileStatus.FileHash
    , email : Maybe Evergreen.V316.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V316.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) Evergreen.V316.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) DiscordFrontendCurrentUser)
