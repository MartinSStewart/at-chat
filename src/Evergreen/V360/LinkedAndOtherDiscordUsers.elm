module Evergreen.V360.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V360.Discord
import Evergreen.V360.DiscordUserData
import Evergreen.V360.EmailAddress
import Evergreen.V360.FileStatus
import Evergreen.V360.PersonName
import Evergreen.V360.UserColor
import Evergreen.V360.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V360.PersonName.PersonName
    , color : Evergreen.V360.UserColor.UserColor
    , icon : Maybe Evergreen.V360.FileStatus.FileHash
    , email : Maybe Evergreen.V360.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V360.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) Evergreen.V360.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) DiscordFrontendCurrentUser)
