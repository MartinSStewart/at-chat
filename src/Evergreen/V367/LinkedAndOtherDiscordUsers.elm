module Evergreen.V367.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V367.Discord
import Evergreen.V367.DiscordUserData
import Evergreen.V367.EmailAddress
import Evergreen.V367.FileStatus
import Evergreen.V367.PersonName
import Evergreen.V367.UserColor
import Evergreen.V367.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V367.PersonName.PersonName
    , color : Evergreen.V367.UserColor.UserColor
    , icon : Maybe Evergreen.V367.FileStatus.FileHash
    , email : Maybe Evergreen.V367.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V367.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) Evergreen.V367.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) DiscordFrontendCurrentUser)
