module Evergreen.V403.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V403.Discord
import Evergreen.V403.DiscordUserData
import Evergreen.V403.EmailAddress
import Evergreen.V403.FileStatus
import Evergreen.V403.PersonName
import Evergreen.V403.UserColor
import Evergreen.V403.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V403.PersonName.PersonName
    , color : Evergreen.V403.UserColor.UserColor
    , icon : Maybe Evergreen.V403.FileStatus.FileHash
    , email : Maybe Evergreen.V403.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V403.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) Evergreen.V403.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) DiscordFrontendCurrentUser)
