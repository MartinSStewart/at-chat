module Evergreen.V364.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V364.Discord
import Evergreen.V364.DiscordUserData
import Evergreen.V364.EmailAddress
import Evergreen.V364.FileStatus
import Evergreen.V364.PersonName
import Evergreen.V364.UserColor
import Evergreen.V364.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V364.PersonName.PersonName
    , color : Evergreen.V364.UserColor.UserColor
    , icon : Maybe Evergreen.V364.FileStatus.FileHash
    , email : Maybe Evergreen.V364.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V364.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) Evergreen.V364.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) DiscordFrontendCurrentUser)
