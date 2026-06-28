module Evergreen.V295.Game exposing (..)

import Array
import Evergreen.V295.Go
import Evergreen.V295.Id
import Evergreen.V295.Message
import Evergreen.V295.SecretId
import Evergreen.V295.UserSession
import Evergreen.V295.WordSpellingGame


type FrontendGameData
    = FrontendGameData_Go Evergreen.V295.Go.ValidatedSetup (Array.Array Evergreen.V295.Go.ActionWithTime) Evergreen.V295.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V295.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V295.WordSpellingGame.ActionWithTime) Evergreen.V295.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V295.SecretId.SecretId Evergreen.V295.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.UserSession.ToBeFilledInByBackend (Evergreen.V295.SecretId.SecretId Evergreen.V295.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) Evergreen.V295.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) Evergreen.V295.WordSpellingGame.LocalChange


type Model
    = GoModel Evergreen.V295.Go.Model
    | WordSpellingGameModel Evergreen.V295.WordSpellingGame.Model


type BackendGameData
    = GameData_Go Evergreen.V295.Go.ValidatedSetup (Array.Array Evergreen.V295.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V295.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V295.WordSpellingGame.ActionWithTime) Evergreen.V295.WordSpellingGame.Shared


type Msg
    = GoGameMsg Evergreen.V295.Go.GameMsg
    | GoSetupMsg Evergreen.V295.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V295.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V295.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V295.Message.Game
    | NoOpMsg
