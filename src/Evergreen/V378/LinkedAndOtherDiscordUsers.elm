module Evergreen.V378.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V378.Discord
import Evergreen.V378.DiscordUserData
import Evergreen.V378.EmailAddress
import Evergreen.V378.FileStatus
import Evergreen.V378.PersonName
import Evergreen.V378.UserColor
import Evergreen.V378.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V378.PersonName.PersonName
    , color : Evergreen.V378.UserColor.UserColor
    , icon : Maybe Evergreen.V378.FileStatus.FileHash
    , email : Maybe Evergreen.V378.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V378.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) Evergreen.V378.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) DiscordFrontendCurrentUser)
