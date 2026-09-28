module Evergreen.V389.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V389.Discord
import Evergreen.V389.DiscordUserData
import Evergreen.V389.EmailAddress
import Evergreen.V389.FileStatus
import Evergreen.V389.PersonName
import Evergreen.V389.UserColor
import Evergreen.V389.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V389.PersonName.PersonName
    , color : Evergreen.V389.UserColor.UserColor
    , icon : Maybe Evergreen.V389.FileStatus.FileHash
    , email : Maybe Evergreen.V389.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V389.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) Evergreen.V389.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) DiscordFrontendCurrentUser)
