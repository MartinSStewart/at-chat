module Evergreen.V384.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V384.Discord
import Evergreen.V384.DiscordUserData
import Evergreen.V384.EmailAddress
import Evergreen.V384.FileStatus
import Evergreen.V384.PersonName
import Evergreen.V384.UserColor
import Evergreen.V384.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V384.PersonName.PersonName
    , color : Evergreen.V384.UserColor.UserColor
    , icon : Maybe Evergreen.V384.FileStatus.FileHash
    , email : Maybe Evergreen.V384.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V384.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) Evergreen.V384.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) DiscordFrontendCurrentUser)
