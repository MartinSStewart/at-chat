module Evergreen.V383.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V383.Discord
import Evergreen.V383.DiscordUserData
import Evergreen.V383.EmailAddress
import Evergreen.V383.FileStatus
import Evergreen.V383.PersonName
import Evergreen.V383.UserColor
import Evergreen.V383.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V383.PersonName.PersonName
    , color : Evergreen.V383.UserColor.UserColor
    , icon : Maybe Evergreen.V383.FileStatus.FileHash
    , email : Maybe Evergreen.V383.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V383.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) Evergreen.V383.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) DiscordFrontendCurrentUser)
