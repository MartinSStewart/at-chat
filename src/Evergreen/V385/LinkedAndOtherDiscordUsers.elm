module Evergreen.V385.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V385.Discord
import Evergreen.V385.DiscordUserData
import Evergreen.V385.EmailAddress
import Evergreen.V385.FileStatus
import Evergreen.V385.PersonName
import Evergreen.V385.UserColor
import Evergreen.V385.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V385.PersonName.PersonName
    , color : Evergreen.V385.UserColor.UserColor
    , icon : Maybe Evergreen.V385.FileStatus.FileHash
    , email : Maybe Evergreen.V385.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V385.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) Evergreen.V385.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) DiscordFrontendCurrentUser)
