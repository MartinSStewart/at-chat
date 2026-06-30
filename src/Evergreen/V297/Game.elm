module Evergreen.V297.Game exposing (..)

import Array
import Evergreen.V297.Go
import Evergreen.V297.Id
import Evergreen.V297.Message
import Evergreen.V297.SecretId
import Evergreen.V297.UserSession
import Evergreen.V297.WordSpellingGame


type FrontendGameData
    = FrontendGameData_Go Evergreen.V297.Go.ValidatedSetup (Array.Array Evergreen.V297.Go.ActionWithTime) Evergreen.V297.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V297.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V297.WordSpellingGame.ActionWithTime) Evergreen.V297.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V297.SecretId.SecretId Evergreen.V297.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.UserSession.ToBeFilledInByBackend (Evergreen.V297.SecretId.SecretId Evergreen.V297.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) Evergreen.V297.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) Evergreen.V297.WordSpellingGame.LocalChange


type Model
    = GoModel Evergreen.V297.Go.Model
    | WordSpellingGameModel Evergreen.V297.WordSpellingGame.Model


type BackendGameData
    = GameData_Go Evergreen.V297.Go.ValidatedSetup (Array.Array Evergreen.V297.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V297.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V297.WordSpellingGame.ActionWithTime) Evergreen.V297.WordSpellingGame.Shared


type Msg
    = GoGameMsg Evergreen.V297.Go.GameMsg
    | GoSetupMsg Evergreen.V297.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V297.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V297.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V297.Message.Game
    | NoOpMsg
