module Evergreen.V413.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V413.Discord
import Evergreen.V413.DiscordUserData
import Evergreen.V413.EmailAddress
import Evergreen.V413.FileStatus
import Evergreen.V413.PersonName
import Evergreen.V413.UserColor
import Evergreen.V413.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V413.PersonName.PersonName
    , color : Evergreen.V413.UserColor.UserColor
    , icon : Maybe Evergreen.V413.FileStatus.FileHash
    , email : Maybe Evergreen.V413.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V413.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) Evergreen.V413.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) DiscordFrontendCurrentUser)
