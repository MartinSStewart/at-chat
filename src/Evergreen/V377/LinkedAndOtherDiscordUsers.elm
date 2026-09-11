module Evergreen.V377.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V377.Discord
import Evergreen.V377.DiscordUserData
import Evergreen.V377.EmailAddress
import Evergreen.V377.FileStatus
import Evergreen.V377.PersonName
import Evergreen.V377.UserColor
import Evergreen.V377.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V377.PersonName.PersonName
    , color : Evergreen.V377.UserColor.UserColor
    , icon : Maybe Evergreen.V377.FileStatus.FileHash
    , email : Maybe Evergreen.V377.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V377.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) Evergreen.V377.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) DiscordFrontendCurrentUser)
