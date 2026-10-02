module Evergreen.V396.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V396.Discord
import Evergreen.V396.DiscordUserData
import Evergreen.V396.EmailAddress
import Evergreen.V396.FileStatus
import Evergreen.V396.PersonName
import Evergreen.V396.UserColor
import Evergreen.V396.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V396.PersonName.PersonName
    , color : Evergreen.V396.UserColor.UserColor
    , icon : Maybe Evergreen.V396.FileStatus.FileHash
    , email : Maybe Evergreen.V396.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V396.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) Evergreen.V396.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) DiscordFrontendCurrentUser)
