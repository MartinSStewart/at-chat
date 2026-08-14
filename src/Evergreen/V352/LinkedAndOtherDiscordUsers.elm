module Evergreen.V352.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V352.Discord
import Evergreen.V352.DiscordUserData
import Evergreen.V352.EmailAddress
import Evergreen.V352.FileStatus
import Evergreen.V352.PersonName
import Evergreen.V352.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V352.PersonName.PersonName
    , icon : Maybe Evergreen.V352.FileStatus.FileHash
    , email : Maybe Evergreen.V352.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V352.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) Evergreen.V352.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) DiscordFrontendCurrentUser)
