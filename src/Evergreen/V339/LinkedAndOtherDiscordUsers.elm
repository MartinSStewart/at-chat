module Evergreen.V339.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V339.Discord
import Evergreen.V339.DiscordUserData
import Evergreen.V339.EmailAddress
import Evergreen.V339.FileStatus
import Evergreen.V339.PersonName
import Evergreen.V339.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V339.PersonName.PersonName
    , icon : Maybe Evergreen.V339.FileStatus.FileHash
    , email : Maybe Evergreen.V339.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V339.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) Evergreen.V339.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) DiscordFrontendCurrentUser)
