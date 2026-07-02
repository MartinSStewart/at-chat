module Evergreen.V299.Game exposing (..)

import Array
import Evergreen.V299.Go
import Evergreen.V299.Id
import Evergreen.V299.Message
import Evergreen.V299.SecretId
import Evergreen.V299.UserSession
import Evergreen.V299.WordSpellingGame


type Msg
    = GoGameMsg Evergreen.V299.Go.GameMsg
    | GoSetupMsg Evergreen.V299.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V299.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V299.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V299.Message.Game
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V299.Go.ValidatedSetup (Array.Array Evergreen.V299.Go.ActionWithTime) Evergreen.V299.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V299.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V299.WordSpellingGame.ActionWithTime) Evergreen.V299.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V299.SecretId.SecretId Evergreen.V299.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.UserSession.ToBeFilledInByBackend (Evergreen.V299.SecretId.SecretId Evergreen.V299.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) Evergreen.V299.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) Evergreen.V299.WordSpellingGame.LocalChange


type Model
    = GoModel_Setup Evergreen.V299.Go.SetupModel
    | GoModel_Game Evergreen.V299.Go.GameModel
    | WordSpellingGame_Setup Evergreen.V299.WordSpellingGame.SetupModel
    | WordSpellingGame_Game Evergreen.V299.WordSpellingGame.GameData


type BackendGameData
    = GameData_Go Evergreen.V299.Go.ValidatedSetup (Array.Array Evergreen.V299.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V299.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V299.WordSpellingGame.ActionWithTime) Evergreen.V299.WordSpellingGame.Shared
