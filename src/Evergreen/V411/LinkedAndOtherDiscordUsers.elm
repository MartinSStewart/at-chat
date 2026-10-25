module Evergreen.V411.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V411.Discord
import Evergreen.V411.DiscordUserData
import Evergreen.V411.EmailAddress
import Evergreen.V411.FileStatus
import Evergreen.V411.PersonName
import Evergreen.V411.UserColor
import Evergreen.V411.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V411.PersonName.PersonName
    , color : Evergreen.V411.UserColor.UserColor
    , icon : Maybe Evergreen.V411.FileStatus.FileHash
    , email : Maybe Evergreen.V411.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V411.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) Evergreen.V411.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) DiscordFrontendCurrentUser)
