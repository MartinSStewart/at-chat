module Evergreen.V406.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V406.Discord
import Evergreen.V406.DiscordUserData
import Evergreen.V406.EmailAddress
import Evergreen.V406.FileStatus
import Evergreen.V406.PersonName
import Evergreen.V406.UserColor
import Evergreen.V406.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V406.PersonName.PersonName
    , color : Evergreen.V406.UserColor.UserColor
    , icon : Maybe Evergreen.V406.FileStatus.FileHash
    , email : Maybe Evergreen.V406.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V406.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) Evergreen.V406.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) DiscordFrontendCurrentUser)
