module Evergreen.V404.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V404.Discord
import Evergreen.V404.DiscordUserData
import Evergreen.V404.EmailAddress
import Evergreen.V404.FileStatus
import Evergreen.V404.PersonName
import Evergreen.V404.UserColor
import Evergreen.V404.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V404.PersonName.PersonName
    , color : Evergreen.V404.UserColor.UserColor
    , icon : Maybe Evergreen.V404.FileStatus.FileHash
    , email : Maybe Evergreen.V404.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V404.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) Evergreen.V404.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) DiscordFrontendCurrentUser)
