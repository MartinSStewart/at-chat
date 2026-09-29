module Evergreen.V392.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V392.Discord
import Evergreen.V392.DiscordUserData
import Evergreen.V392.EmailAddress
import Evergreen.V392.FileStatus
import Evergreen.V392.PersonName
import Evergreen.V392.UserColor
import Evergreen.V392.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V392.PersonName.PersonName
    , color : Evergreen.V392.UserColor.UserColor
    , icon : Maybe Evergreen.V392.FileStatus.FileHash
    , email : Maybe Evergreen.V392.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V392.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) Evergreen.V392.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) DiscordFrontendCurrentUser)
