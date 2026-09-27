module Evergreen.V387.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V387.Discord
import Evergreen.V387.DiscordUserData
import Evergreen.V387.EmailAddress
import Evergreen.V387.FileStatus
import Evergreen.V387.PersonName
import Evergreen.V387.UserColor
import Evergreen.V387.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V387.PersonName.PersonName
    , color : Evergreen.V387.UserColor.UserColor
    , icon : Maybe Evergreen.V387.FileStatus.FileHash
    , email : Maybe Evergreen.V387.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V387.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) Evergreen.V387.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) DiscordFrontendCurrentUser)
