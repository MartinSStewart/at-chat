module Evergreen.V405.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V405.Discord
import Evergreen.V405.DiscordUserData
import Evergreen.V405.EmailAddress
import Evergreen.V405.FileStatus
import Evergreen.V405.PersonName
import Evergreen.V405.UserColor
import Evergreen.V405.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V405.PersonName.PersonName
    , color : Evergreen.V405.UserColor.UserColor
    , icon : Maybe Evergreen.V405.FileStatus.FileHash
    , email : Maybe Evergreen.V405.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V405.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) Evergreen.V405.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) DiscordFrontendCurrentUser)
