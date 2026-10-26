module Evergreen.V414.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V414.Discord
import Evergreen.V414.DiscordUserData
import Evergreen.V414.EmailAddress
import Evergreen.V414.FileStatus
import Evergreen.V414.PersonName
import Evergreen.V414.UserColor
import Evergreen.V414.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V414.PersonName.PersonName
    , color : Evergreen.V414.UserColor.UserColor
    , icon : Maybe Evergreen.V414.FileStatus.FileHash
    , email : Maybe Evergreen.V414.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V414.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) Evergreen.V414.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) DiscordFrontendCurrentUser)
