module Evergreen.V298.Game exposing (..)

import Array
import Evergreen.V298.Go
import Evergreen.V298.Id
import Evergreen.V298.Message
import Evergreen.V298.SecretId
import Evergreen.V298.UserSession
import Evergreen.V298.WordSpellingGame


type Msg
    = GoGameMsg Evergreen.V298.Go.GameMsg
    | GoSetupMsg Evergreen.V298.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V298.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V298.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V298.Message.Game
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V298.Go.ValidatedSetup (Array.Array Evergreen.V298.Go.ActionWithTime) Evergreen.V298.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V298.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V298.WordSpellingGame.ActionWithTime) Evergreen.V298.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V298.SecretId.SecretId Evergreen.V298.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.UserSession.ToBeFilledInByBackend (Evergreen.V298.SecretId.SecretId Evergreen.V298.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) Evergreen.V298.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) Evergreen.V298.WordSpellingGame.LocalChange


type Model
    = GoModel_Setup Evergreen.V298.Go.SetupModel
    | GoModel_Game Evergreen.V298.Go.GameModel
    | WordSpellingGame_Setup Evergreen.V298.WordSpellingGame.SetupModel
    | WordSpellingGame_Game Evergreen.V298.WordSpellingGame.GameData


type BackendGameData
    = GameData_Go Evergreen.V298.Go.ValidatedSetup (Array.Array Evergreen.V298.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V298.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V298.WordSpellingGame.ActionWithTime) Evergreen.V298.WordSpellingGame.Shared
