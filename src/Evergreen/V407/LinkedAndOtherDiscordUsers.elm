module Evergreen.V407.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V407.Discord
import Evergreen.V407.DiscordUserData
import Evergreen.V407.EmailAddress
import Evergreen.V407.FileStatus
import Evergreen.V407.PersonName
import Evergreen.V407.UserColor
import Evergreen.V407.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V407.PersonName.PersonName
    , color : Evergreen.V407.UserColor.UserColor
    , icon : Maybe Evergreen.V407.FileStatus.FileHash
    , email : Maybe Evergreen.V407.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V407.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) Evergreen.V407.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) DiscordFrontendCurrentUser)
