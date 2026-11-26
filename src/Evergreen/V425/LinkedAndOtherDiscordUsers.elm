module Evergreen.V425.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V425.Discord
import Evergreen.V425.DiscordUserData
import Evergreen.V425.EmailAddress
import Evergreen.V425.FileStatus
import Evergreen.V425.PersonName
import Evergreen.V425.UserColor
import Evergreen.V425.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V425.PersonName.PersonName
    , color : Evergreen.V425.UserColor.UserColor
    , icon : Maybe Evergreen.V425.FileStatus.FileHash
    , email : Maybe Evergreen.V425.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V425.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) Evergreen.V425.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) DiscordFrontendCurrentUser)
