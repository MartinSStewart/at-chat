module Evergreen.V366.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V366.Discord
import Evergreen.V366.DiscordUserData
import Evergreen.V366.EmailAddress
import Evergreen.V366.FileStatus
import Evergreen.V366.PersonName
import Evergreen.V366.UserColor
import Evergreen.V366.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V366.PersonName.PersonName
    , color : Evergreen.V366.UserColor.UserColor
    , icon : Maybe Evergreen.V366.FileStatus.FileHash
    , email : Maybe Evergreen.V366.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V366.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) Evergreen.V366.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) DiscordFrontendCurrentUser)
