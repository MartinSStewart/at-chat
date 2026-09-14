module Evergreen.V382.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V382.Discord
import Evergreen.V382.DiscordUserData
import Evergreen.V382.EmailAddress
import Evergreen.V382.FileStatus
import Evergreen.V382.PersonName
import Evergreen.V382.UserColor
import Evergreen.V382.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V382.PersonName.PersonName
    , color : Evergreen.V382.UserColor.UserColor
    , icon : Maybe Evergreen.V382.FileStatus.FileHash
    , email : Maybe Evergreen.V382.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V382.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) Evergreen.V382.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) DiscordFrontendCurrentUser)
