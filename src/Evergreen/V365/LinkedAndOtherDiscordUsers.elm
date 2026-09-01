module Evergreen.V365.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V365.Discord
import Evergreen.V365.DiscordUserData
import Evergreen.V365.EmailAddress
import Evergreen.V365.FileStatus
import Evergreen.V365.PersonName
import Evergreen.V365.UserColor
import Evergreen.V365.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V365.PersonName.PersonName
    , color : Evergreen.V365.UserColor.UserColor
    , icon : Maybe Evergreen.V365.FileStatus.FileHash
    , email : Maybe Evergreen.V365.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V365.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) Evergreen.V365.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) DiscordFrontendCurrentUser)
