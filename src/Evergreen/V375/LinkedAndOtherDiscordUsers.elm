module Evergreen.V375.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V375.Discord
import Evergreen.V375.DiscordUserData
import Evergreen.V375.EmailAddress
import Evergreen.V375.FileStatus
import Evergreen.V375.PersonName
import Evergreen.V375.UserColor
import Evergreen.V375.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V375.PersonName.PersonName
    , color : Evergreen.V375.UserColor.UserColor
    , icon : Maybe Evergreen.V375.FileStatus.FileHash
    , email : Maybe Evergreen.V375.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V375.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) Evergreen.V375.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) DiscordFrontendCurrentUser)
