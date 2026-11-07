module Evergreen.V421.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V421.Discord
import Evergreen.V421.DiscordUserData
import Evergreen.V421.EmailAddress
import Evergreen.V421.FileStatus
import Evergreen.V421.PersonName
import Evergreen.V421.UserColor
import Evergreen.V421.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V421.PersonName.PersonName
    , color : Evergreen.V421.UserColor.UserColor
    , icon : Maybe Evergreen.V421.FileStatus.FileHash
    , email : Maybe Evergreen.V421.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V421.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) Evergreen.V421.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) DiscordFrontendCurrentUser)
