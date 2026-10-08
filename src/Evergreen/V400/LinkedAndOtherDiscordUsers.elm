module Evergreen.V400.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V400.Discord
import Evergreen.V400.DiscordUserData
import Evergreen.V400.EmailAddress
import Evergreen.V400.FileStatus
import Evergreen.V400.PersonName
import Evergreen.V400.UserColor
import Evergreen.V400.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V400.PersonName.PersonName
    , color : Evergreen.V400.UserColor.UserColor
    , icon : Maybe Evergreen.V400.FileStatus.FileHash
    , email : Maybe Evergreen.V400.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V400.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) Evergreen.V400.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) DiscordFrontendCurrentUser)
