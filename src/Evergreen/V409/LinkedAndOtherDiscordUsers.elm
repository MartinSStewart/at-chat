module Evergreen.V409.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V409.Discord
import Evergreen.V409.DiscordUserData
import Evergreen.V409.EmailAddress
import Evergreen.V409.FileStatus
import Evergreen.V409.PersonName
import Evergreen.V409.UserColor
import Evergreen.V409.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V409.PersonName.PersonName
    , color : Evergreen.V409.UserColor.UserColor
    , icon : Maybe Evergreen.V409.FileStatus.FileHash
    , email : Maybe Evergreen.V409.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V409.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) Evergreen.V409.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) DiscordFrontendCurrentUser)
