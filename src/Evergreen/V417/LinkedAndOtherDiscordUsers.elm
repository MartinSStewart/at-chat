module Evergreen.V417.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V417.Discord
import Evergreen.V417.DiscordUserData
import Evergreen.V417.EmailAddress
import Evergreen.V417.FileStatus
import Evergreen.V417.PersonName
import Evergreen.V417.UserColor
import Evergreen.V417.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V417.PersonName.PersonName
    , color : Evergreen.V417.UserColor.UserColor
    , icon : Maybe Evergreen.V417.FileStatus.FileHash
    , email : Maybe Evergreen.V417.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V417.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) Evergreen.V417.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) DiscordFrontendCurrentUser)
