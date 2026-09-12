module Evergreen.V379.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V379.Discord
import Evergreen.V379.DiscordUserData
import Evergreen.V379.EmailAddress
import Evergreen.V379.FileStatus
import Evergreen.V379.PersonName
import Evergreen.V379.UserColor
import Evergreen.V379.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V379.PersonName.PersonName
    , color : Evergreen.V379.UserColor.UserColor
    , icon : Maybe Evergreen.V379.FileStatus.FileHash
    , email : Maybe Evergreen.V379.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V379.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) Evergreen.V379.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) DiscordFrontendCurrentUser)
