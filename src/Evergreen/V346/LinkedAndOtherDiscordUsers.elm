module Evergreen.V346.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V346.Discord
import Evergreen.V346.DiscordUserData
import Evergreen.V346.EmailAddress
import Evergreen.V346.FileStatus
import Evergreen.V346.PersonName
import Evergreen.V346.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V346.PersonName.PersonName
    , icon : Maybe Evergreen.V346.FileStatus.FileHash
    , email : Maybe Evergreen.V346.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V346.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) Evergreen.V346.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) DiscordFrontendCurrentUser)
