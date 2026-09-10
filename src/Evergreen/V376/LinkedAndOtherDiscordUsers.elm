module Evergreen.V376.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V376.Discord
import Evergreen.V376.DiscordUserData
import Evergreen.V376.EmailAddress
import Evergreen.V376.FileStatus
import Evergreen.V376.PersonName
import Evergreen.V376.UserColor
import Evergreen.V376.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V376.PersonName.PersonName
    , color : Evergreen.V376.UserColor.UserColor
    , icon : Maybe Evergreen.V376.FileStatus.FileHash
    , email : Maybe Evergreen.V376.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V376.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) Evergreen.V376.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) DiscordFrontendCurrentUser)
