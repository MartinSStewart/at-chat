module Evergreen.V423.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V423.Discord
import Evergreen.V423.DiscordUserData
import Evergreen.V423.EmailAddress
import Evergreen.V423.FileStatus
import Evergreen.V423.PersonName
import Evergreen.V423.UserColor
import Evergreen.V423.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V423.PersonName.PersonName
    , color : Evergreen.V423.UserColor.UserColor
    , icon : Maybe Evergreen.V423.FileStatus.FileHash
    , email : Maybe Evergreen.V423.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V423.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) Evergreen.V423.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) DiscordFrontendCurrentUser)
